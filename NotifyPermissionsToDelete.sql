USE PostItReplacement
GO
/****** Object:  StoredProcedure [perm].[NotifyPermissionsToDelete]    Script Date: 09/27/2022 8:56:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/******************************************************************************
* Description: 	Notifies DBAs of expiring permissions 
*			
* Procedure Test: 

	EXEC sys.sp_recompile @objname = N'perm.NotifyPermissionsToDelete'
	EXEC perm.NotifyPermissionsToDelete @debugOutput = 1

* Change History:
* -----------------------------------------------------------------------------
* Date			|Author				|Reason
* -----------------------------------------------------------------------------
* 10/03/2022	Sharon Reid			Initial Release

*******************************************************************************/

CREATE OR ALTER PROCEDURE [perm].[NotifyPermissionsToDelete]
(
	@debugOutput BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;

SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
--drop table #t
CREATE TABLE #t (username NVARCHAR(50) NOT NULL,
                 servername NVARCHAR(50) NOT NULL,
                 databasename NVARCHAR(50) NULL,
                 expirationdate DATE NOT NULL,
				 requestedby NVARCHAR(50) NOT NULL,
				 requestedbyemail NVARCHAR(100) NOT NULL,
                 permissiontype NVARCHAR(50) NULL,
                 rolename NVARCHAR(50) NULL,
                 securableobject NVARCHAR(128) NULL,
                 securablepermission NVARCHAR(50) NULL,
				 IsActive BIT NOT NULL);

INSERT INTO #t
SELECT username,
       servername,
       databasename,
       expirationdate,
	   RequestedBy,
	   RequestedByEmail,
       permissiontype,
       rolename,
       securableobject,
       securablepermission,
	   IsActive
FROM perm.PermissionsToDelete
WHERE expirationdate <= DATEADD(DAY, 5, GETDATE())
	AND IsActive = 1
ORDER BY expirationdate, username, servername, databasename;

IF (EXISTS (SELECT * FROM #t))
BEGIN
    BEGIN TRY
        DECLARE @profile sysname;
        DECLARE @t TABLE (VALUE sysname,
                          Data sysname NULL)

        INSERT INTO @t
        EXEC master.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'DatabaseMailProfile';

        SET @profile = (SELECT TOP 1 Data FROM @t);
        IF ((@profile IS NULL) OR (@profile = ''))
        BEGIN
            SET @profile = (   SELECT TOP 1
                                      p.name
                               FROM msdb.dbo.sysmail_profile AS p
                               JOIN msdb.dbo.sysmail_principalprofile pp
                                       ON p.profile_id = pp.profile_id
                               WHERE pp.is_default = 1);
        END;

        IF EXISTS (   SELECT *
                      FROM #t
                      WHERE expirationdate <= DATEADD(DAY, 5, GETDATE()))

        BEGIN
			declare @currRequestor nVarchar( 256 );
			DECLARE @subject NVARCHAR(500), @tableHTML NVARCHAR(MAX);
			
			declare requestorCursor cursor local fast_Forward for
				select distinct
					RequestedByEmail
				from
					#t;
			open requestorCursor;
			fetch next from requestorCursor into @currRequestor;

			WHILE( @@fetch_Status = 0 )
			BEGIN
				SET @subject = N'Permissions will be deleted soon';
				SET @tableHTML
					= N'<style>
										td
										{font-family:arial;
										border-left:1px solid black;
										border-top:1px solid black;}
										table
										{font-family:arial;
										border-collapse: collapse;
										border-right:1px solid black;
										border-bottom:1px solid black;}
										th
										{font-family:arial;
										border-left:1px solid black;
										border-top:1px solid black;
										color: Maroon;
										background-color: Silver;
										font-weight: normal;
										text-align: left;}
									  </style>' + N'<body>' + N'<div STYLE="font-family:arial;font-weight:bold">'
					  + N' Permissions will be deleted soon</div></br></b>
									These permissions will be revoked by the Expiration Date. 
									Please see DBAs to change the deletion date if needed. <br></br>'
					  + N'<table cellpadding="6">'
					  + N'<tr><th>UserName</th><th>ServerName</th><th>DatabaseName</th><th>ExpirationDate</th><th>RequestedBy</th><th>PermissionType</th><th>RoleName</th><th>SecurableObject</th><th>SecurablePermission</th></tr>
'
					  + CAST((   SELECT td = username,
										'',
										td = servername,
										'',
										td = databasename,
										'',
										td = expirationdate,							
										'',
										td = requestedby,
										'',
										td = permissiontype,
										'',
										td = rolename,
										'',
										td = securableobject,
										'',
										td = securablepermission,
										'
'
								 FROM #t
								 WHERE RequestedByEmail = @currRequestor
								 FOR XML PATH('tr'), ELEMENTS XSINIL) AS NVARCHAR(MAX)) + N'</table>' + N'</body>';

				EXEC sys.xp_logevent 500001, @subject, WARNING;

				IF( @debugOutput = 1 )
				BEGIN
					DECLARE @dbgOutput NVARCHAR(MAX) = N'exec msdb.sp_send_dbmail @profile_name = ' + @profile + N',
					@body = ' + @tableHTML + N',
					@body_format = ''HTML'',
					@importantce = ''Normal'',
					@subject = ' + @subject + N';'

					PRINT @dbgOutput;
				END
				ELSE
				BEGIN
					EXEC msdb.sp_send_dbmail @profile_name = @profile,
												 --@recipients = 'sharon.reid.harris@gmail.com',
												 @recipients = @currRequestor,
												 @body = @tableHTML,
												 @body_format = 'HTML',
												 @importance = 'Normal',
												 @subject = @subject;
				END;

				FETCH NEXT FROM requestorCursor INTO @currRequestor;
			END;

			CLOSE requestorCursor;
			DEALLOCATE requestorCursor;
        END;
    END TRY
    BEGIN CATCH

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @ErrorLine INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE(),
               @ErrorLine = ERROR_LINE();
        SET @ErrorMessage = @ErrorMessage + N' Line #' + CAST(@ErrorLine AS VARCHAR(10));
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState) WITH LOG;

    END CATCH;

    DROP TABLE #t;

END;

END
