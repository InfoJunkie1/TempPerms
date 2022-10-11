USE PostItReplacement 
GO 

--create a schema
CREATE SCHEMA perm AUTHORIZATION dbo 
GO

--Now to create a SQL authenticated login
--Eek!Password4Demo!
USE [master]
GO
CREATE LOGIN [SharonFromAccounting] WITH PASSWORD=N'Eek!Password4Demo!', 
	DEFAULT_DATABASE=[tempdb], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
USE [PostItReplacement]
GO
--CREATE USER [SharonFromAccounting] FOR LOGIN [SharonFromAccounting]
--GO
