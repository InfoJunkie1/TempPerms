/*
Automated Temporary Permissions Process 
Sharon Reid
sharon.reid.harris@gmail.com
https://github.com/InfoJunkie1/TempPerms.git
*/

USE PostItReplacement
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE OR ALTER PROCEDURE [perm].[DeleteTempPerms](@debug BIT = 0)
AS
/******************************************************************************
* Description: Stored procedure to delete temporary permissions from TempPerms table
*			   	
*			
* Procedure Test: 
	
	EXEC perm.DeleteTempPerms @Debug = 1

* Change History:
* -----------------------------------------------------------------------------
* Date			|Author				|Reason
* -----------------------------------------------------------------------------
* 10/03/2022	Sharon Reid		Initial Release
*******************************************************************************/
BEGIN

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRANSACTION;
	BEGIN TRY

		IF EXISTS
			(	SELECT	*
				FROM	perm.TempPerms AS pd
				WHERE	IsActive = 'true'
						AND IsApplied = 'true'
						AND pd.ExpirationDate < GETDATE()
			)

		--DECLARE  @ServerName sysname = syn.fnGetHostName();

		BEGIN
			DECLARE @PermDeleteID BIGINT,
					@username NVARCHAR(50),
					@dbname sysname,
					@RoleName NVARCHAR(50),
					@IsSecurable BIT,
					@IsSchema BIT,
					@SecurableObject NVARCHAR(128),
					@SecurablePermission NVARCHAR(50),
					@IsActive BIT,
					@IsApplied BIT,
					@IsServerPerm BIT,
					@IsSQLuser BIT,
					@i INT;

			DECLARE @PermCursor CURSOR;
			DECLARE @sql NVARCHAR(MAX);

			DECLARE	@exists bit,
					@parmDef nVarchar(max) = N'@principalName nvarchar(max), @exists bit OUTPUT',
					@sqlt nVarchar(max)

			DECLARE PermCursor CURSOR FAST_FORWARD LOCAL FOR
				SELECT	pd.PermDeleteID,
						pd.UserName,
						pd.DatabaseName,
						pd.RoleName,
						pd.IsSecurable,
						pd.IsSchema,
						pd.SecurableObject,
						pd.SecurablePermission,
						pd.IsActive,
						pd.IsApplied,
						pd.IsServerPerm,
						pd.IsSQLuser
				FROM	perm.TempPerms AS pd
				WHERE	IsActive = 'true'
						AND IsApplied = 'true'
						AND pd.ExpirationDate <= GETDATE();

			OPEN PermCursor;
			FETCH NEXT FROM PermCursor
			INTO @PermDeleteID,
				 @username,
				 @dbname,
				 @RoleName,
				 @IsSecurable,
				 @IsSchema,
				 @SecurableObject,
				 @SecurablePermission,
				 @IsActive,
				 @IsApplied,
				 @IsServerPerm,
				 @IsSQLuser;

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
				--check for missing user and mark IsActive = 0 if found
				SET @sqlt = N'select @exists = 
					case 
						When not exists( select * from [' + @dbName + N'].[sys].[database_principals] where name = @principalName ) Then 0
					else 1 
					end;';

				exec sp_executesql @sqlt, @parmDef, @username, @exists output;

				IF( @exists = 0)
					BEGIN
						IF @debug = 1
							PRINT 'update perm.tempPerms
									set 
										isActive = 0
									where
										permDeleteId = ' + CONVERT(VARCHAR(MAX), @PermDeleteID) + ';';
							ELSE
								UPDATE	perm.TempPerms
								SET IsActive = 0
								WHERE	PermDeleteID = @PermDeleteID;
					END 

				ELSE
					BEGIN 
						--delete server permissions if role
						IF(@IsSecurable = 0 AND @IsServerPerm = 1)
						BEGIN
							SET @sql
								= 'Use Master; 
								IF( EXISTS( SELECT * FROM sys.server_principals WHERE type = ''R'' AND name = ''' + @RoleName
								  + N''' ) )
								BEGIN
									ALTER SERVER ROLE [' + @RoleName + N'] DROP MEMBER [' + @username + N'];
								END';
							IF @Debug = 1 PRINT @sql;
							ELSE EXEC sp_executesql @sql;
						END;

						--delete server permissions if securable on server
						IF(@IsSecurable = 1 AND @IsSchema = 0 and @IsServerPerm = 1)
						BEGIN
							SET @sql
								= N'Use Master;	Revoke ' + @SecurablePermission + N' to ' + N'[' + @username + N']';
							IF @Debug = 1 PRINT @sql;
							ELSE EXEC sp_executesql @sql;
						END;
						
						--delete database permissions if role
						IF(@IsSecurable = 0)
						BEGIN
							SET @sql
								= 'USE ' + @dbname + ';
							IF( EXISTS( SELECT * FROM sys.database_principals WHERE type = ''R'' AND name = ''' + @RoleName  + ''' ) )
							BEGIN
								ALTER ROLE [' + @RoleName + '] Drop MEMBER [' + @username + '];
							END;';

							IF @debug = 1 PRINT @sql;
							ELSE EXEC sp_executesql @sql;
						END;

						--delete database permissions if securable but not schema
						IF(@IsSecurable = 1 AND @IsSchema = 0)
						BEGIN
							SET @sql
								= 'Use ' + @dbname + ';	Revoke ' + @SecurablePermission + ' on ' + @SecurableObject
									+ ' to ' + '[' + @username + ']';
							IF @debug = 1 PRINT @sql;
							ELSE EXEC sp_executesql @sql;
						END;

						--delete database permissions if schema
						IF(@IsSecurable = 1 AND @IsSchema = 1)
						BEGIN
							SET @sql
								= 'Use ' + @dbname + ';	Revoke ' + @SecurablePermission + ' on schema::' + @SecurableObject
									+ ' to ' + '[' + @username + ']';
							IF @debug = 1 PRINT @sql;
							ELSE EXEC sp_executesql @sql;
						END;

						--Update IsActive = false
						IF @debug = 1
							PRINT 'update perm.TempPerms
									set 
										isActive = 0
									where
										permDeleteId = ' + CONVERT(VARCHAR(MAX), @PermDeleteID) + ';';
						ELSE
							UPDATE	perm.TempPerms
							SET IsActive = 0
							WHERE	PermDeleteID = @PermDeleteID;

					END 

				FETCH NEXT FROM PermCursor
				INTO @PermDeleteID,
					 @username,
					 @dbname,
					 @RoleName,
					 @IsSecurable,
					 @IsSchema,
					 @SecurableObject,
					 @SecurablePermission,
					 @IsActive,
					 @IsApplied,
					@IsServerPerm,
					@IsSQLuser;

			END;

			CLOSE PermCursor;
			DEALLOCATE PermCursor;

		END;	

		IF @debug = 1 PRINT @sql;
		ELSE EXEC sp_executesql @sql;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT;
		SELECT	@ErrorMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();

		IF(XACT_STATE() = -1)
		BEGIN
			ROLLBACK TRANSACTION;
		END;

		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH;

	IF(XACT_STATE() = 1)
	BEGIN
		COMMIT TRANSACTION;
	END;
END;




