/*
Automated Temporary Permissions Process 
Sharon Reid
sharon.reid.harris@gmail.com
https://github.com/InfoJunkie1/TempPerms.git
*/

--ApplyTempPermissions
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'ApplyTempPermissions', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Sharon', @job_id = @jobId OUTPUT --update operator
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Apply Temp Permissions', @server_name = N'UpdateHere' --update here
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Apply Temp Permissions', @step_name=N'Apply temp permissions', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec perm.ApplyTempPerms', 
		@database_name=N'PostItReplacement', --update here
		@flags=20
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'Apply Temp Permissions', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Sharon', --update here
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Apply Temp Permissions', @name=N'Every 5 min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20221009, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

--Notify when temp permissions expiring
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'NotifyPermsExpiring', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Sharon', @job_id = @jobId OUTPUT --update here
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'NotifyPermsExpiring', @server_name = N'Update here' --update here
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'NotifyPermsExpiring', @step_name=N'NotifyPermsExpiring', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec perm.NotifyPermissionsToDelete', 
		@database_name=N'PostItReplacement', 
		@flags=16
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'NotifyPermsExpiring', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Sharon', --update here
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'NotifyPermsExpiring', @name=N'Daily0600', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20221009, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO

--Delete and archive expired temp perms
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'DeleteArchiveTempPerms', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Sharon', @job_id = @jobId OUTPUT --update here
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'DeleteArchiveTempPerms', @server_name = N'Update here' --update here
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'DeleteArchiveTempPerms', @step_name=N'DeleteTempPerms', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec perm.DeleteTempPerms', 
		@database_name=N'PostItReplacement', 
		@flags=8
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'DeleteArchiveTempPerms', @step_name=N'ArchiveExpiredTempPerms', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec perm.ArchiveExpiredTempPerms', 
		@database_name=N'PostItReplacement', 
		@flags=8
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'DeleteArchiveTempPerms', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Sharon', --update here
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DeleteArchiveTempPerms', @name=N'Hourly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20221009, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO
