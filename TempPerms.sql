USE PostItReplacement;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE perm.TempPerms
    (
        PermDeleteID BIGINT IDENTITY(1, 1) NOT NULL
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
      , DateAdded DATETIME NOT NULL
      , Comments NVARCHAR(128) NULL
      , AddedBy NVARCHAR(50) NULL
      , IsActive BIT NOT NULL
      , IsApplied BIT NOT NULL
      , IsServerPerm BIT NULL
      , IsSQLuser BIT NULL
      , HoursToExpiration AS (DATEDIFF(HOUR, GETDATE(), ExpirationDate))
	  , StartDateTime DATETIME NULL 

    )
GO

ALTER TABLE perm.TempPerms
ADD CONSTRAINT DF_ExpiredPermissions_DateAdded
    DEFAULT (GETDATE()) FOR DateAdded;
GO

ALTER TABLE perm.TempPerms
ADD CONSTRAINT DF_ExpiredPermissions_AddedBy
    DEFAULT (SUSER_SNAME()) FOR AddedBy;
GO

ALTER TABLE perm.TempPerms
ADD CONSTRAINT DF_Permissions_IsActive
    DEFAULT ('true') FOR IsActive
GO

ALTER TABLE perm.TempPerms
ADD CONSTRAINT DF__Permissions__IsApplied
    DEFAULT ((0)) FOR IsApplied;
GO

ALTER TABLE perm.TempPerms
ADD CONSTRAINT DF__Permissions_IsSQLuser
    DEFAULT ('0') FOR issqluser;
GO


