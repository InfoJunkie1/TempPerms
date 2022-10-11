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

CREATE OR ALTER PROCEDURE perm.ArchiveExpiredTempPerms --@aiDaysExpired INT = 4
AS
/******************************************************************************
* Description: 	Purges the temporary individual permission entries that are no longer 
*				active due to expiration from the active table
*			
* Procedure Test: 

	EXEC perm.ArchiveExpiredTempPerms;

* Change History:
* -----------------------------------------------------------------------------
* Date			|Author				|Reason
* -----------------------------------------------------------------------------
* 2022-10-03	Sharon Reid			Initial Release
*							
*******************************************************************************/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRANSACTION;
	BEGIN TRY
		DECLARE @i INT = 0;

		INSERT INTO perm.TempPerms_Archive(PermDeleteID,
													ServerName,
													DatabaseName,
													UserName,
													PermissionType,
													RoleName,
													IsSecurable,
													IsSchema,
													SecurableObject,
													SecurablePermission,
													RequestedBy,
													RequestedByEmail,
													ExpirationDate,
													DateAdded,
													Comments,
													AddedBy)
		SELECT	PermDeleteID,
				ServerName,
				DatabaseName,
				UserName,
				PermissionType,
				RoleName,
				IsSecurable,
				IsSchema,
				SecurableObject,
				SecurablePermission,
				RequestedBy,
				RequestedByEmail,
				ExpirationDate,
				DateAdded,
				Comments,
				AddedBy
		FROM	perm.TempPerms
		WHERE IsActive = 0

		DELETE	FROM perm.TempPerms
		WHERE IsActive = 0

		SET @i = @@rowCount;

		IF(@i > 0)
		BEGIN
			RAISERROR('Archived %d additional individual permissions entries which were not active', 10, 1, @i) WITH LOG;
		END;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT;
		SELECT	@ErrorMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();

		IF(XACT_STATE() = -1)BEGIN
		ROLLBACK TRANSACTION;
		END;

		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH;

	IF(XACT_STATE() = 1)BEGIN
	COMMIT TRANSACTION;
	END;

END;
GO


