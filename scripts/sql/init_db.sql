
/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'BaseballFrTest' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'BaseballFrTest' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'BaseballFrTest' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BaseballFrTest')
BEGIN
    ALTER DATABASE BaseballFrTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BaseballFrTest;
END;
GO

-- Create the 'BaseballFrTest' database
CREATE DATABASE BaseballFrTest;
GO

USE BaseballFrTest;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
