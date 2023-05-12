/*************************************************
Ditching the Post-Its demo
Sharon Reid
New Stars of Data
May 12, 2023
*************************************************/

USE PostItReplacement
GO

/*************************************************
Example 1--database level with role
*************************************************/

--will be using SQL Authenticated users but also works with Windows authenticated

--Add PamFromTheOffice as user in PostItReplacement with db_datareader role via SQL Pane expires in two days
	--show PamFromTheOffice currently not a user and no permissions

--Manually execute job ApplyTempPermissions

--Manually execute job NotifyPermsExpiring and show via iPhone

--update expiration date to past
	UPDATE perm.TempPerms
	SET ExpirationDate = '2023-05-7'
	WHERE UserName = 'PamFromTheOffice'
	AND RoleName = 'db_datareader'

select * from perm.TempPerms_Archive

--Delete perms and archive row
	EXEC msdb.dbo.sp_start_job 'DeleteArchiveTempPerms'

--Show PamFromTheOffice no longer has read in PostItReplacement

--Show TempPerms_Archive now has recent entry for PamFromTheOffice
SELECT * FROM perm.TempPerms
SELECT * FROM perm.TempPerms_Archive


/*************************************************
Example 2--database level with securables
*************************************************/

--Add entry for PamFromTheOffice to give her insert on person.person in AdventureWorks2019 and select on sales schema

-- PermDeleteID, HoursToExpiration, DateAdded, AddedBy, IsActive and IsApplied are not included as they have defaults
INSERT INTO perm.TempPerms
		(
		ServerName, DatabaseName, UserName, PermissionType, RoleName, IsSecurable, IsSchema
		, SecurableObject, SecurablePermission, RequestedBy, RequestedByEmail, ExpirationDate
		, Comments, IsServerPerm, IsSQLuser
		)
	VALUES ('Desktop-4DSMHFB', 'AdventureWorks2019', 'PamFromTheOffice', 'grant', NULL, 1, 0
			, 'person.person', 'insert', 'Sharon Reid', 'sharon.reid.harris@gmail.com', '2023-05-28'
			, 'ticket#', Null, 1)

select * from perm.TempPerms

--Add entry for PamFromTheOffice to grant select on the sales schema in AW
INSERT INTO perm.TempPerms
		(
		-- PermDeleteID, HoursToExpiration, DateAdded, AddedBy, IsActive and IsApplied are not included as they are defaulted
		ServerName, DatabaseName, UserName, PermissionType, RoleName, IsSecurable, IsSchema
		, SecurableObject, SecurablePermission, RequestedBy, RequestedByEmail, ExpirationDate
		, Comments, IsServerPerm, IsSQLuser
		)
	VALUES ('Desktop-4DSMHFB', 'AdventureWorks2019', 'PamFromTheOffice', 'grant', NULL, 1, 1
			, 'sales', 'select', 'Sharon Reid', 'sharon.reid.harris@gmail.com', '2023-05-28'
			, 'ticket#', Null, 1)

select * from perm.TempPerms

/*************************************************
Show sproc to apply perms
*************************************************/

--Run that job to apply those perms!
--Perms in AdventureWorks2019
EXEC msdb.dbo.sp_start_job 'ApplyTempPermissions'

/*************************************************
Example 3--server level with role
Can you grant server permissions? Why yes, yes you can
*************************************************/

--Granting AllisonSwimsWithGators sysadmin (server role) for one hour
INSERT INTO perm.TempPerms
		(
		-- PermDeleteID, HoursToExpiration, DateAdded, AddedBy, IsActive and IsApplied are not included as they are defaulted
		ServerName, DatabaseName, UserName, PermissionType, RoleName, IsSecurable, IsSchema
		, SecurableObject, SecurablePermission, RequestedBy, RequestedByEmail, ExpirationDate
		, Comments, IsServerPerm, IsSQLuser
		)
	VALUES ('Desktop-4DSMHFB', NULL, 'AllisonSwimsWithGators', 'grant', 'sysadmin', 0, 0
			, null, null, 'Sharon Reid', 'sharon.reid.harris@gmail.com', '2023-05-12 20:00'
			, 'ticket#', 1, 1)

SELECT * FROM perm.TempPerms

/*************************************************
Example 4--server level with securables
*************************************************/

--Granting AllisonSwimsWithGators alter trace (server securable) 
INSERT INTO perm.TempPerms
		(
		-- PermDeleteID, HoursToExpiration, DateAdded, AddedBy, IsActive and IsApplied are not included as they are defaulted
		ServerName, DatabaseName, UserName, PermissionType, RoleName, IsSecurable, IsSchema
		, SecurableObject, SecurablePermission, RequestedBy, RequestedByEmail, ExpirationDate
		, Comments, IsServerPerm, IsSQLuser
		)
	VALUES ('Desktop-4DSMHFB', NULL, 'AllisonSwimsWithGators', 'grant', NULL, 1, 0
			, null, 'alter trace', 'Sharon Reid', 'sharon.reid.harris@gmail.com', '2023-05-28'
			, 'ticket#', 1, 1)

SELECT * FROM perm.TempPerms

--Run that job to apply those perms!
EXEC msdb.dbo.sp_start_job 'ApplyTempPermissions'

--Let's make sure the delete job only deletes expired permissions

UPDATE perm.TempPerms
SET ExpirationDate = '2023-05-01'
WHERE username = 'AllisonSwimsWithGators'
AND RoleName = 'sysadmin'

SELECT * FROM perm.TempPerms

/*************************************************
Show NotifyPermissionsToDelete sproc
	ArchiveExpiredTempPerms sproc
	DeleteTempPerms sproc
*************************************************/

--Run that job to delete and archive those expired perms!
EXEC msdb.dbo.sp_start_job 'DeleteArchiveTempPerms'

SELECT * FROM perm.TempPerms
SELECT * FROM perm.TempPerms_Archive






/*************************************************
Example 5--Error handling: no SQL authenticated login
*************************************************/

--add update to not applied yet
EXEC perm.ApplyTempPerms 1

--No login created for SQL Authenticated login
INSERT INTO perm.TempPerms
		(
		-- PermDeleteID, HoursToExpiration, DateAdded, AddedBy, IsActive and IsApplied are not included as they are defaulted
		ServerName, DatabaseName, UserName, PermissionType, RoleName, IsSecurable, IsSchema
		, SecurableObject, SecurablePermission, RequestedBy, RequestedByEmail, ExpirationDate
		, Comments, IsServerPerm, IsSQLuser
		)
	VALUES ('Desktop-4DSMHFB', 'AdventureWorks2019', 'ThunderFalcon', 'grant', NULL, 1, 0
			, 'person.person', 'insert', 'Sharon Reid', 'sharon.reid.harris@gmail.com', '2023-05-28'
			, 'ticket#', Null, 1)

EXEC perm.ApplyTempPerms
---look at error message

--clean up
DELETE FROM perm.TempPerms
WHERE username = 'ThunderFalcon'

/*************************************************
Example 6--Error handling: Missing user in database
*************************************************/

--User still in TempPerms table but no longer in database (will be marked inactive)
INSERT INTO perm.TempPerms
		(
		-- PermDeleteID, HoursToExpiration, DateAdded, AddedBy, IsActive and IsApplied are not included as they are defaulted
		ServerName, DatabaseName, UserName, PermissionType, RoleName, IsSecurable, IsSchema
		, SecurableObject, SecurablePermission, RequestedBy, RequestedByEmail, ExpirationDate
		, Comments, IsServerPerm, IsSQLuser
		)
	VALUES ('Desktop-4DSMHFB', 'PostItReplacement', 'KatieArchivesMedievalHistory', 'grant', 'db_datawriter', 0, 0
			, Null, Null, 'Sharon Reid', 'sharon.reid.harris@gmail.com', '2023-05-28'
			, 'ticket#', Null, 1)

--run job troubleshoot
EXEC msdb.dbo.sp_start_job 'ApplyTempPermissions'

DROP USER KatieArchivesMedievalHistory

UPDATE perm.TempPerms
SET ExpirationDate = '2023-05-01'
WHERE username = 'KatieArchivesMedievalHistory'


EXEC msdb.dbo.sp_start_job 'DeleteArchiveTempPerms'



