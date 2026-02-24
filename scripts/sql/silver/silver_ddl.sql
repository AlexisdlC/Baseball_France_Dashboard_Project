/*
============================================================================
DDL Script: Create Silver Tables
============================================================================
Script Purpose:
  This script create tables in the "Silver" schema, dropping existing tables
if they already exist.
Run this script to redefine the DDL structure of 'Silver' Tables
============================================================================
*/

IF OBJECT_ID('silver.games_data', 'U') IS NOT NULL
	DROP TABLE silver.games_data;

CREATE TABLE silver.games_data (
	game_id						INT,
	game_date					DATE,
	game_type					NVARCHAR(50),
	game_type_regular_or_post	NVARCHAR(50),
	game_status					NVARCHAR(50),
	home_team_id				INT,
	away_team_id				INT,
	doubleheader				NVARCHAR(50),
	game_num					INT,
	home_score					INT,
	away_score					INT,
	venue_id					INT,
	venue_name					NVARCHAR(50),
	winning_team_id				NVARCHAR(50),
	losing_team_id				NVARCHAR(50),
	winning_pitcher				NVARCHAR(50),
	losing_pitcher				NVARCHAR(50),
	save_pitcher				NVARCHAR(50)
);

IF OBJECT_ID('silver.game_statcast_data', 'U') IS NOT NULL
	DROP TABLE silver.game_statcast_data;

CREATE TABLE silver.game_statcast_data (
	game_id								INT,
	batter_id							INT,
	stand								NVARCHAR(50),
	pitcher_id							INT,
	p_throws							NVARCHAR(50),
	at_bat_number						INT,
	inning								INT,
	inning_topbot						NVARCHAR(50),
	outs_when_up						INT,
	number_runner_on_base				INT,
	runners_in_scoring_position			NVARCHAR(50),
	balls								INT,
	strikes								INT,
	at_bat_count						NVARCHAR(50),
	pitch_number						INT,
	pitch_type							NVARCHAR(50),
	pitch_name							NVARCHAR(50),
	release_speed						FLOAT,
	release_extension					FLOAT,
	effective_speed						FLOAT,
	release_spin_rate					INT,
	release_pos_x						FLOAT,
	release_pos_y						FLOAT,
	release_pos_z						FLOAT,
	arm_angle							FLOAT,
	speed_x_50ft						FLOAT,
	speed_y_50ft						FLOAT,
	speed_z_50ft						FLOAT,
	accel_x_50ft						FLOAT,
	accel_y_50ft						FLOAT,
	accel_z_50ft						FLOAT,
	pitch_horizontal_movement			FLOAT,
	pitch_vertical_movement				FLOAT,
	pitch_vertical_movement_gravity		FLOAT,
	batter_top_zone						FLOAT,
	batter_bot_zone						FLOAT,
	pitch_plate_x_location				FLOAT,
	pitch_plate_z_location				FLOAT,
	pitch_zone_plate_location			INT,
	bat_speed							FLOAT,
	swing_length						FLOAT,
	launch_speed						FLOAT,
	launch_angle						INT,
	attack_angle						FLOAT,
	attack_direction					FLOAT,
	swing_path_tilt						FLOAT,
	intercept_point_x_batter_inches		FLOAT,
	intercept_point_y_batter_inches		FLOAT,
	launch_speed_angle_category			INT,
	projected_hit_distance				INT,
	hit_location_x						FLOAT,
	hit_location_y						FLOAT,
	pitch_result_short					NVARCHAR(50),
	pitch_result_description			NVARCHAR(50),
	batted_ball_type					NVARCHAR(50),
	pitch_event							NVARCHAR(50),
	home_score							INT,
	post_home_score						INT,
	away_score							INT,
	post_away_score						INT,
	bat_score							INT,	
	post_bat_score						INT,
	fld_score							INT,
	post_fld_score						INT,
	home_delta_win_exp					FLOAT,
	pitcher_delta_run_exp				FLOAT,
	batter_delta_run_exp				FLOAT
);

IF OBJECT_ID('silver.batters_data', 'U') IS NOT NULL
	DROP TABLE silver.batters_data;

CREATE TABLE silver.batters_data (
	name_last			NVARCHAR(50),
	name_first			NVARCHAR(50),
	player_id			INT,
	first_season		DATE,
	last_season			DATE
);

IF OBJECT_ID('silver.pitchers_data', 'U') IS NOT NULL
	DROP TABLE silver.pitchers_data;

CREATE TABLE silver.pitchers_data (
	name_last			NVARCHAR(50),
	name_first			NVARCHAR(50),
	player_id			INT,
	first_season		DATE,
	last_season			DATE
);

IF OBJECT_ID('silver.teams_data', 'U') IS NOT NULL
	DROP TABLE silver.teams_data;

CREATE TABLE silver.teams_data(
	team_id				INT,
	team_name			NVARCHAR(50),
	team_code			NVARCHAR(50),
	file_code			NVARCHAR(50),
	team_abbreviation	NVARCHAR(50),
	location_name		NVARCHAR(50),
	short_name			NVARCHAR(50)
);

IF OBJECT_ID('silver.batting_boxscore_data', 'U') IS NOT NULL
	DROP TABLE silver.batting_boxscore_data;

CREATE TABLE silver.batting_boxscore_data (
	player_id		INT,
	at_bat			INT,
	runs			INT,
	hits			INT,
	doubles			INT,
	triples			INT,
	home_run		INT,
	rbi				INT,
	stolen_bases	INT,
	walk			INT,
	strikeout		INT,
	hit_by_pitch	INT,
	sac_fly			INT,
	game_id			INT,
	team_id			INT
);

IF OBJECT_ID('silver.pitching_boxscore_data', 'U') IS NOT NULL
	DROP TABLE silver.pitching_boxscore_data;

CREATE TABLE silver.pitching_boxscore_data (
	player_id					INT,
	innings_pitched				VARCHAR(50),
	hits						INT,
	runs						INT,
	earned_runs					INT,
	walks						INT,
	strikeouts					INT,
	home_runs					INT,
	hit_by_pitch				INT,
	batters_faced				INT,
	inherited_runners			INT,
	inherited_runners_scored	INT,
	game_id						INT,
	team_id						INT,
	outs						INT
);