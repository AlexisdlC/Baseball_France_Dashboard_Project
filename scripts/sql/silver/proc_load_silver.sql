/*
==================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==================================================================================
Script Purpose:
  This stored procedure loads data in the 'Silver' schema from the tables in the 'Bronze' schema.
  It perfoms the following actions:
    - Truncates the silver tables before loading data.
    - Inserts transformed and cleansed data from bronze into silver tables.

Parameters: 
  None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
  EXEC silver.load_silver;
==================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS

BEGIN

	-- Preventing SQL to send "Rows Affected" messages so the procedure can run smoothly and completely when
	-- called with python
	SET NOCOUNT ON

	DECLARE @start_time DATETIME, @end_time DATETIME, @global_start_time DATETIME;

	SET @global_start_time = GETDATE();

	PRINT '=================================';
	PRINT 'Loading Silver Layer';
	PRINT '=================================';

	SET @start_time = GETDATE();

	PRINT '---------------------------------------------------------------';
	PRINT '>> Truncating Table: silver.game_data';
	PRINT '---------------------------------------------------------------';

	TRUNCATE TABLE silver.games_data

	PRINT '---------------------------------------------------------------';
	PRINT '>> Inserting Data Into: silver.game_data';
	PRINT '---------------------------------------------------------------';

	INSERT INTO silver.games_data (
		game_id,
		game_date,
		game_type,
		game_type_regular_or_post,
		game_status,
		home_team_id,
		away_team_id,
		doubleheader,
		game_num,
		home_score,
		away_score,
		venue_id,
		venue_name,
		winning_team_id,
		losing_team_id,
		winning_pitcher,
		losing_pitcher,
		save_pitcher
	)

	SELECT
		game_id,
		game_date,
		game_type,
		-- Create a Postseason/Regular Season Column
		CASE
			WHEN game_type = 'R' THEN 'Regular'
			ELSE 'Postseason'
		END AS game_type_regular_or_post,
		status AS game_status,
		home_id,
		away_id,
		doubleheader,
		game_num,
		home_score,
		away_score,
		venue_id,
		venue_name,
		-- Identify if winning team is home or away team to get the winning team id
		CASE
			WHEN winning_team = home_name THEN home_id
			WHEN winning_team = away_name THEN away_id
			ELSE
				CASE
					WHEN home_score > away_score THEN home_id
					WHEN home_score < away_score THEN away_id
					ELSE NULL
				END
		END AS winning_team_id,
		CASE
		-- Identify if losing team is home or away team to get the losing team id
			WHEN winning_team = home_name THEN away_id
			WHEN winning_team = away_name THEN home_id
			ELSE 
				CASE
					WHEN home_score > away_score THEN away_id
					WHEN home_score < away_score THEN home_id
					ELSE NULL
				END
		END AS losing_team_id,
		winning_pitcher,
		losing_pitcher,
		save_pitcher
	FROM (
		-- Use ROW_NUMBER over a partition of game_ids to remove duplicate entry of games
		SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY game_id ORDER BY game_date DESC) AS flag_last
		FROM bronze.game_data
	)t
	WHERE t.flag_last = 1

	SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	SET @start_time = GETDATE();

	PRINT '---------------------------------------------------------------';
	PRINT '>> Truncating Table: silver.game_statcast_data';
	PRINT '---------------------------------------------------------------';

	TRUNCATE TABLE silver.game_statcast_data

	PRINT '---------------------------------------------------------------';
	PRINT '>> Inserting Data Into: silver.game_statcast_data';
	PRINT '---------------------------------------------------------------';
	
	INSERT INTO silver.game_statcast_data (
		game_id,
		batter_id,
		stand,
		pitcher_id,
		p_throws,
		at_bat_number,
		inning,
		inning_topbot,
		outs_when_up,
		number_runner_on_base,
		runners_in_scoring_position,
		balls,
		strikes,
		at_bat_count,
		pitch_number,
		pitch_type,
		pitch_name,
		release_speed,
		release_extension,
		effective_speed,
		release_spin_rate,
		release_pos_x,
		release_pos_y,
		release_pos_z,
		arm_angle,
		speed_x_50ft,
		speed_y_50ft,
		speed_z_50ft,
		accel_x_50ft,
		accel_y_50ft,
		accel_z_50ft,
		pitch_horizontal_movement,
		pitch_vertical_movement,
		pitch_vertical_movement_gravity,
		batter_top_zone,
		batter_bot_zone,
		pitch_plate_x_location,
		pitch_plate_z_location,
		pitch_zone_plate_location,
		bat_speed,
		swing_length,
		launch_speed,
		launch_angle,
		attack_angle,
		attack_direction,
		swing_path_tilt,
		intercept_point_x_batter_inches,
		intercept_point_y_batter_inches,
		launch_speed_angle_category,
		projected_hit_distance,
		hit_location_x,
		hit_location_y,
		pitch_result_short,
		pitch_result_description,
		batted_ball_type,
		pitch_event,
		home_score,
		post_home_score,
		away_score,
		post_away_score,
		bat_score,	
		post_bat_score,
		fld_score,
		post_fld_score,
		home_delta_win_exp,
		pitcher_delta_run_exp,
		batter_delta_run_exp	
	)

	SELECT
		game_pk AS game_id,
		batter AS batter_id,
		stand,
		pitcher AS pitcher_id,
		p_throws,
		at_bat_number,
		inning,
		inning_topbot,
		outs_when_up,
		-- Use the on_1b, on_2b and on_3b columns to identify how many runners are on base
		CASE
			WHEN on_1b IS NOT NULL THEN 1
			ELSE 0
		END +
		CASE
			WHEN on_2b IS NOT NULL THEN 1
			ELSE 0
		END +
		CASE
			WHEN on_3b IS NOT NULL THEN 1
			ELSE 0
		END
		AS number_runner_on_base,
		-- Use the on_2b and on_3b columns to identify if runners are in scoring position
		CASE
			WHEN on_2b IS NOT NULL OR on_3b IS NOT NULL THEN 'with'
			ELSE 'wihout'
		END AS runners_in_scoring_position,
		balls,
		strikes,
		-- Create a count column by concatenating the balls and strikes columns
		CONCAT(CAST(balls AS NVARCHAR), '-', CAST(strikes AS NVARCHAR)) AS at_bat_count,
		pitch_number,
		pitch_type,
		pitch_name,
		release_speed,
		release_extension,
		effective_speed,
		release_spin_rate,
		release_pos_x,
		release_pos_y,
		release_pos_z,
		arm_angle,
		-- Convert speeds from ft/s to mph
		ROUND(vx0/1.46,1) AS speed_x_50ft,
		ROUND(vy0/1.46,1) AS speed_y_50ft,
		ROUND(vz0/1.46,1) AS speed_z_50ft,
		-- Convert accelerations from ft per second per second to miles per hour per hour
		ROUND(ax*2454,1) AS accel_x_50ft,
		ROUND(ay*2454,1) AS accel_y_50ft,
		ROUND(az*2454,1) AS accel_z_50ft,
		pfx_x AS pitch_horizontal_movement,
		pfx_z AS pitch_vertical_movement,
		api_break_z_with_gravity AS pitch_vertical_movement_gravity,
		sz_top AS batter_top_zone,
		sz_bot AS batter_bot_zone,
		plate_x AS pitch_plate_x_location,
		plate_z AS pitch_plate_z_location,
		zone AS pitch_zone_plate_location,
		bat_speed,
		swing_length,
		launch_speed,
		launch_angle,
		attack_angle,
		attack_direction,
		swing_path_tilt,
		intercept_ball_minus_batter_pos_x_inches AS intercept_point_x_batter_inches,
		intercept_ball_minus_batter_pos_y_inches AS intercept_point_y_batter_inches,
		launch_speed_angle AS launch_speed_angle_category,
		hit_distance_sc AS projected_hit_distance,
		hc_x AS hit_location_x,
		hc_y AS hit_location_y,
		type AS pitch_result_short,
		description AS pitch_result_description,
		-- Treat nulls in batted_ball_type and pitch_event as 'n/a'
		COALESCE(bb_type, 'n/a') AS batted_ball_type,
		COALESCE(events, 'n/a') AS pitch_event,
		home_score,
		post_home_score,
		away_score,
		post_away_score,
		bat_score,
		post_bat_score,
		fld_score,
		post_fld_score,
		delta_home_win_exp,
		delta_pitcher_run_exp,
		-- Convert Run Expectancy to be from the perspective of the batter instead of pitcher
		delta_pitcher_run_exp * (-1)
	FROM bronze.game_statcast_data

	SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	SET @start_time = GETDATE();

	PRINT '---------------------------------------------------------------';
	PRINT '>> Truncating Table: silver.batters_data';
	PRINT '---------------------------------------------------------------';

	TRUNCATE TABLE silver.batters_data;

	PRINT '---------------------------------------------------------------';
	PRINT '>> Inserting Data Into: silver.batters_data';
	PRINT '---------------------------------------------------------------';

	INSERT INTO silver.batters_data (
	-- Rename columns to standardize names and so they are more user friendly
		name_last,
		name_first,
		player_id,
		first_season,
		last_season
	)

	SELECT
		name_last,
		name_first,
		-- Rename id to player_id
		key_mlbam AS player_id,
		-- Cast debut year as DATE type
		CAST(CAST(mlb_played_first AS NVARCHAR) AS DATE)AS mlb_played_first,
		-- Cast final year as DATE type
		CAST(CAST(mlb_played_last AS NVARCHAR) AS DATE) AS mlb_played_last
	FROM bronze.batters_data;

	SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	SET @start_time = GETDATE();

	PRINT '---------------------------------------------------------------';
	PRINT '>> Truncating Table: silver.pitchers_data';
	PRINT '---------------------------------------------------------------';

	TRUNCATE TABLE silver.pitchers_data;

	PRINT '---------------------------------------------------------------';
	PRINT '>> Inserting Data Into: silver.pitchers_data';
	PRINT '---------------------------------------------------------------';

	INSERT INTO silver.pitchers_data (
	-- Rename columns to standardize names and so they are more user friendly
		name_last,
		name_first,
		player_id,
		first_season,
		last_season
	)

	SELECT
		name_last,
		name_first,
		-- Rename id to player_id
		key_mlbam AS player_id,
		-- Cast debut year as DATE type
		CAST(CAST(mlb_played_first AS NVARCHAR) AS DATE)AS mlb_played_first,
		-- Cast final year as DATE type
		CAST(CAST(mlb_played_last AS NVARCHAR) AS DATE) AS mlb_played_last
	FROM bronze.pitchers_data;

	SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	SET @start_time = GETDATE();

	PRINT '---------------------------------------------------------------';
	PRINT '>> Truncating Table: silver.teams_data';
	PRINT '---------------------------------------------------------------';

	TRUNCATE TABLE silver.teams_data;

	PRINT '---------------------------------------------------------------';
	PRINT '>> Inserting Data Into: silver.teams_data';
	PRINT '---------------------------------------------------------------';

	INSERT INTO silver.teams_data (
	-- Rename columns to standardize names and so they are more user friendly
		team_id,
		team_name,
		team_code,
		file_code,
		team_abbreviation,
		location_name,
		short_name
	)

	SELECT
		id,
		name,
		teamCode,
		fileCode,
		teamName,
		locationName,
		shortName
	FROM bronze.teams_data;

	SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	SET @start_time = GETDATE();

	PRINT '---------------------------------------------------------------';
	PRINT '>> Truncating Table: silver.batting_boxscore_data';
	PRINT '---------------------------------------------------------------';

	TRUNCATE TABLE silver.batting_boxscore_data;

	PRINT '------------------------------------------------------------------';
	PRINT '>> Inserting Data Into: silver.batting_boxscore_data';
	PRINT '------------------------------------------------------------------';

	INSERT INTO silver.batting_boxscore_data (
	-- Rename columns to standardize names and so they are more user friendly
		player_id,
		at_bat,
		runs,
		hits,
		doubles,
		triples,
		home_run,
		rbi,
		stolen_bases,
		walk,
		strikeout,
		hit_by_pitch,
		sac_fly,
		game_id,
		team_id
	)

	SELECT
		personId,
		ab,
		r,
		h,
		doubles,
		triples,
		hr,
		rbi,
		sb,
		bb,
		k,
		hbp,
		sf,
		gameId,
		team_id
	FROM (
	-- Removing few duplicate entries of player and game
		SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY gameId, personId ORDER BY gameId DESC) AS flag_last
		FROM bronze.batting_boxscore_data
		WHERE gameId IS NOT NULL AND personId IS NOT NULL
	)t
	WHERE flag_last = 1;

	SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	SET @start_time = GETDATE();

	PRINT '---------------------------------------------------------------';
	PRINT '>> Truncating Table: silver.pitching_boxscore_data';
	PRINT '---------------------------------------------------------------';

	TRUNCATE TABLE silver.pitching_boxscore_data;

	PRINT '----------------------------------------------------------------';
	PRINT '>> Inserting Data Into: silver.pitching_boxscore_data';
	PRINT '----------------------------------------------------------------';

	INSERT INTO silver.pitching_boxscore_data (
	-- Rename columns to standardize names and so they are more user friendly
		player_id,
		innings_pitched,
		hits,
		runs,
		earned_runs,
		walks,
		strikeouts,
		home_runs,
		hit_by_pitch,
		batters_faced,
		game_id,
		team_id,
		outs
	)

	SELECT
		personId,
		ip,
		h,
		r,
		er,
		bb,
		k,
		hr,
		hbp,
		bat_faced,
		gameId,
		team_id,
		outs
	FROM (
	-- Removing few duplicate entries of player and game
		SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY gameId, personId ORDER BY gameId DESC) AS flag_last
		FROM bronze.pitching_boxscore_data
		WHERE gameId IS NOT NULL AND personId IS NOT NULL
	)t
	WHERE flag_last = 1;

	SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	PRINT '=====================================';
	PRINT 'Loading Of Silver Layer Is Completed';
	PRINT '		>> Total Load Duration: ' + CAST(DATEDIFF(second, @global_start_time, @end_time) AS NVARCHAR) + ' seconds';
	PRINT '=====================================';

END