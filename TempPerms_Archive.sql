USE PostItReplacement
GO

/****** Object:  Table [perm].[PermissionsToDelete_Archive]    Script Date: 09/27/2022 2:33:48 PM ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE perm.TempPerms_Archive
(
    PermDelete_Archive_ID BIGINT IDENTITY(1, 1) NOT NULL,
    PermDeleteID BIGINT NOT NULL,
    ServerName NVARCHAR(50) NOT NULL,
    DatabaseName NVARCHAR(50) NULL,
    UserName NVARCHAR(50) NOT NULL,
    PermissionType NVARCHAR(50) NULL,
    RoleName NVARCHAR(50) NULL,
    IsSecurable BIT NOT NULL,
    IsSchema BIT NOT NULL,
    SecurableObject NVARCHAR(128) NULL,
    SecurablePermission NVARCHAR(50) NULL,
    RequestedBy NVARCHAR(50) NOT NULL,
    RequestedByEmail NVARCHAR(100) NOT NULL,
    ExpirationDate DATETIME NULL,
    DateAdded DATETIME NOT NULL,
    Comments NVARCHAR(128) NULL,
    AddedBy NVARCHAR(50) NULL,
    IsServerPerm BIT NULL,
	IsSQLuser BIT NULL,
    HoursToExpiration AS (DATEDIFF(HOUR, GETDATE(), ExpirationDate)),
	StartDateTime DATETIME NULL 

)
GO

ALTER TABLE perm.TempPerms_Archive
ADD CONSTRAINT DF_ExpiredPermissions_Archive_DateAdded
    DEFAULT (GETDATE()) FOR DateAdded;
GO

ALTER TABLE perm.TempPerms_Archive
ADD CONSTRAINT DF_ExpiredPermissions_Archive_AddedBy
    DEFAULT (SUSER_SNAME()) FOR AddedBy;
GO


