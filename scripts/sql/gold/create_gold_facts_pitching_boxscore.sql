
/*
=================================================================================
Create view to extract create facts table containing pitching boxscores info
=================================================================================
*/

IF OBJECT_ID('gold.facts_pitching_boxscore', 'V') IS NOT NULL
	DROP VIEW  gold.facts_pitching_boxscore
GO



CREATE VIEW gold.facts_pitching_boxscore AS

-- Create CTE containing the game_id and the id of the winning pitcher
WITH CTE_winning_pitchers_id AS (
	SELECT
		g.game_id AS game_id,
		p.player_id AS winning_pitcher_id
	FROM silver.games_data AS g
	LEFT JOIN silver.pitchers_data AS p
	-- JOIN on names. The full name from the pitchers table is build from the name_first and name_last columns using CONCAT
	-- COLLATE is used to remove accents since they are not included in the games table pitchers names
	-- Both names are put in upper cases in order to do the comparison
	ON UPPER(CONCAT(CAST(p.name_first AS VARCHAR) COLLATE SQL_Latin1_General_CP1253_CI_AI,
	' ',
	CAST(p.name_last AS VARCHAR) COLLATE SQL_Latin1_General_CP1253_CI_AI)) = UPPER(g.winning_pitcher)
), 
-- Create CTE containing the game_id and the id of the losing pitcher
CTE_losing_pitcher_id AS (
	SELECT
		g.game_id AS game_id,
		p.player_id AS losing_pitcher_id
	FROM silver.games_data AS g
	LEFT JOIN silver.pitchers_data AS p
	-- JOIN on names. The full name from the pitchers table is build from the name_first and name_last columns using CONCAT
	-- COLLATE is used to remove accents since they are not included in the games table pitchers names
	-- Both names are put in upper cases in order to do the comparison
	ON UPPER(CONCAT(CAST(p.name_first AS VARCHAR) COLLATE SQL_Latin1_General_CP1253_CI_AI,
	' ',
	CAST(p.name_last AS VARCHAR) COLLATE SQL_Latin1_General_CP1253_CI_AI)) = UPPER(g.losing_pitcher)
), 
-- Create CTE containing the game_id and the id of the saving pitcher
CTE_save_pitcher_id AS (
	SELECT
		g.game_id AS game_id,
		p.player_id AS save_pitcher_id
	FROM silver.games_data AS g
	-- JOIN on names. The full name from the pitchers table is build from the name_first and name_last columns using CONCAT
	-- COLLATE is used to remove accents since they are not included in the games table pitchers names
	-- Both names are put in upper cases in order to do the comparison
	LEFT JOIN silver.pitchers_data AS p
	ON UPPER(CONCAT(CAST(p.name_first AS VARCHAR) COLLATE SQL_Latin1_General_CP1253_CI_AI,
	' ',
	CAST(p.name_last AS VARCHAR) COLLATE SQL_Latin1_General_CP1253_CI_AI)) = UPPER(g.save_pitcher)
),
-- Create CTE joining pitching stats and win, loss, save info
CTE_pitching_wls AS (
	SELECT
		player_id,
		p.game_id,
		team_id,
		outs,
		hits,
		runs,
		earned_runs,
		walks,
		strikeouts,
		home_runs,
		hit_by_pitch,
		batters_faced,
		wls_w.winning_pitcher_id,
		wls_l.losing_pitcher_id,
		wls_s.save_pitcher_id
	FROM silver.pitching_boxscore_data AS p
	LEFT JOIN CTE_winning_pitchers_id AS wls_w
	ON wls_w.game_id = p.game_id AND wls_w.winning_pitcher_id = p.player_id
	LEFT JOIN CTE_losing_pitcher_id AS wls_l
	ON wls_l.game_id = p.game_id AND wls_l.losing_pitcher_id = p.player_id
	LEFT JOIN CTE_save_pitcher_id AS wls_s
	ON wls_s.game_id = p.game_id AND wls_s.save_pitcher_id = p.player_id
)

SELECT
	player_id,
	game_id,
	team_id,
	outs,
	hits,
	runs,
	earned_runs,
	walks,
	strikeouts,
	home_runs,
	hit_by_pitch,
	batters_faced,
	-- Convert winning pitcher id to 0/1 for easier aggregation and count
	CASE
		WHEN winning_pitcher_id IS NULL THEN 0
		ELSE 1
	END AS win,
	-- Convert losing pitcher id to 0/1 for easier aggregation and count
	CASE 
		WHEN losing_pitcher_id IS NULL THEN 0
		ELSE 1
	END AS loss,
	-- Convert saving pitcher id to 0/1 for easier aggregation and count
	CASE
		WHEN save_pitcher_id IS NULL THEN 0
		ELSE 1
	END AS sv
FROM CTE_pitching_wls
