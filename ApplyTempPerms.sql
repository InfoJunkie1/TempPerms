USE PostItReplacement
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER       PROCEDURE [perm].[ApplyTempPerms]
(@Debug BIT = 0)
AS
/******************************************************************************
* Description: Stored procedure to apply temporary permissions from PermissionsToDelete table
*			   	
*			
* Procedure Test: 
	
	EXEC perm.ApplyTempPerms @Debug = 1

* Change History:
* -----------------------------------------------------------------------------
* Date			|Author				|Reason
* -----------------------------------------------------------------------------
* 10/03/2022	Sharon Reid		Initial Release
*******************************************************************************/
BEGIN

	SET NOCOUNT ON;
	SET  XACT_ABORT ON;

	BEGIN TRANSACTION;
	BEGIN TRY

		IF EXISTS
			(	SELECT	*
				FROM	perm.PermissionsToDelete AS pd
				WHERE	IsActive = 'true'
						AND IsApplied = 'false')

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
					@IsSQLuser BIT;
			DECLARE @PermCursor CURSOR;
			DECLARE @sql NVARCHAR(MAX);




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
				FROM	perm.PermissionsToDelete AS pd
				WHERE	IsActive = 'true'
						AND IsApplied = 'false';

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

			
				--create login if it doesnt exist
				IF(NOT EXISTS (SELECT *	  FROM sys.server_principals WHERE name = @username))
				BEGIN
					IF @IsSQLuser = 1 
					BEGIN
						SET @sql = N'raiseerror(''SQL login needs to be created manually'', 18, 1) RETURN -1';
						IF @Debug = 1 PRINT @sql;
						ELSE EXEC sp_executesql @sql;
					END
					ELSE 
					BEGIN 
						SET @sql = N'Use Master;	 Create Login ' + N'[' + @username + N']' + N' FROM WINDOWS';
						IF @Debug = 1 PRINT @sql;
						ELSE EXEC sp_executesql @sql;
					END 
				END

				--create user if it doesn't exist
				SET @sql
					= 'IF NOT EXISTS (SELECT * FROM [' + @dbname + '].sys.database_principals WHERE Name = '''
					  + @username + ''') 
					BEGIN
						USE ['	   + @dbname + '];
						Create User ' + '[' + @username + ']' + ' for login ' + '[' + @username + ']
					END';
				IF @Debug = 1 PRINT @sql;
				ELSE EXEC sp_executesql @sql;

				--apply server permissions if role
				IF(@IsSecurable = 0 AND @IsServerPerm = 1)
				BEGIN
					SET @sql
						= 'Use Master; 
						IF( EXISTS( SELECT * FROM sys.server_principals WHERE type = ''R'' AND name = ''' + @RoleName
						  + N''' ) )
						BEGIN
							ALTER SERVER ROLE [' + @RoleName + N'] ADD MEMBER [' + @username + N'];
						END';
					IF @Debug = 1 PRINT @sql;
					ELSE EXEC sp_executesql @sql;
				END;

				--apply server permissions if securable on server
				IF(@IsSecurable = 1 AND @IsSchema = 0 and @IsServerPerm = 1)
				BEGIN
					SET @sql
						= N'Use Master;	Grant ' + @SecurablePermission + N' to ' + N'[' + @username + N']';
					IF @Debug = 1 PRINT @sql;
					ELSE EXEC sp_executesql @sql;
				END;


				--apply database permissions if role
				IF(@IsSecurable = 0)
				BEGIN
					SET @sql
						= N'USE ' + @dbname
						  + N';
							IF( EXISTS( SELECT * FROM sys.database_principals WHERE type = ''R'' AND name = ''' + @RoleName
						  + N''' ) )
						BEGIN
							ALTER ROLE [' + @RoleName + N'] ADD MEMBER [' + @username + N'];
						END;';
					IF @Debug = 1 PRINT @sql;
					ELSE EXEC sp_executesql @sql;
				END;

				--apply database permissions if securable but not schema
				IF(@IsSecurable = 1 AND @IsSchema = 0)
				BEGIN
					SET @sql
						= N'Use ' + @dbname + N';	Grant ' + @SecurablePermission + N' on ' + @SecurableObject
						  + N' to ' + N'[' + @username + N']';
					IF @Debug = 1 PRINT @sql;
					ELSE EXEC sp_executesql @sql;
				END;

				--apply database permissions if schema
				IF(@IsSecurable = 1 AND @IsSchema = 1)
				BEGIN
					SET @sql
						= N'Use ' + @dbname + N';	Grant ' + @SecurablePermission + N' on schema::' + @SecurableObject
						  + N' to ' + N'[' + @username + N']';
					IF @Debug = 1 PRINT @sql;
					ELSE EXEC sp_executesql @sql;
				END;

				--Update IsApplied = true
				IF @Debug = 1
					PRINT 'update perm.permissionsToDelete
						set 
							isApplied = 1
						where
							permDeleteId = ' + CONVERT(VARCHAR(MAX), @PermDeleteID) + ';';
				ELSE
					UPDATE	perm.PermissionsToDelete
					SET IsApplied = 1
					WHERE	PermDeleteID = @PermDeleteID;

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



GO


