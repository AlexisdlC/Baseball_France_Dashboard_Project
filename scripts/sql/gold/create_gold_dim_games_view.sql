/*
=================================================================================
Create view to extract create dimension table containing game info
=================================================================================
*/

IF OBJECT_ID('gold.dim_games', 'V') IS NOT NULL
	DROP VIEW  gold.dim_games
GO

CREATE VIEW gold.dim_games AS

SELECT
	game_id,
	game_date,
	game_type AS game_type_abbr,
	CASE game_type
		WHEN 'R' THEN 'Regular'
		WHEN 'F' THEN 'Wild Card'
		WHEN 'D' THEN 'ALDS'
		WHEN 'L' THEN 'ALCS'
		WHEN 'W' THEN 'World Series'
	END AS game_type,
	home_team_id,
	away_team_id,
	doubleheader AS game_doubleheader,
	game_num AS game_dh_number,
	home_score,
	away_score,
	winning_team_id,
	losing_team_id,
	winning_pitcher AS game_winning_pitcher_name,
	losing_pitcher AS game_losing_pitcher_name,
	save_pitcher AS game_save_pitcher_name
FROM silver.games_data