/*
Automated Temporary Permissions Process 
Sharon Reid
sharon.reid.harris@gmail.com
https://github.com/InfoJunkie1/TempPerms.git
*/

USE PostItReplacement
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE perm.TempPerms_Archive
(
    PermDelete_Archive_ID BIGINT IDENTITY(1, 1) NOT NULL
    , PermDeleteID BIGINT NOT NULL
    , ServerName NVARCHAR(50) NOT NULL
    , DatabaseName NVARCHAR(50) NULL
    , UserName NVARCHAR(50) NOT NULL
    , PermissionType NVARCHAR(50) NULL
    , RoleName NVARCHAR(50) NULL
    , IsSecurable BIT NOT NULL
    , IsSchema BIT NOT NULL
    , SecurableObject NVARCHAR(128) NULL
    , SecurablePermission NVARCHAR(50) NULL
    , RequestedBy NVARCHAR(50) NOT NULL
    , RequestedByEmail NVARCHAR(100) NOT NULL
    , ExpirationDate DATETIME NULL
    , HoursToExpiration AS (DATEDIFF(HOUR, GETDATE(), ExpirationDate))
    , DateAdded DATETIME NOT NULL 
    , Comments NVARCHAR(128) NULL
    , AddedBy NVARCHAR(50) NULL 
    , IsServerPerm BIT NULL
	, IsSQLuser BIT NULL
)
GO




