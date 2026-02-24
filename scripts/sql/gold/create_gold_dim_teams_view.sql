/*
=================================================================================
Create view to extract create dimension table containing team info
=================================================================================
*/

IF OBJECT_ID('gold.dim_teams', 'V') IS NOT NULL
	DROP VIEW  gold.dim_teams
GO

CREATE VIEW gold.dim_teams AS

SELECT
	team_id,
	team_name,
	UPPER(file_code) AS team_code,
	team_abbreviation
FROM silver.teams_data