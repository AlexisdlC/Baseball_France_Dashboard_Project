/*
=================================================================================
Create view to extract create fact table containing stacast data
=================================================================================
*/

IF OBJECT_ID('gold.facts_statcast_data', 'V') IS NOT NULL
	DROP VIEW  gold.facts_statcast_data
GO

CREATE VIEW gold.facts_statcast_data AS

WITH CTE_enhanced_data AS (
	-- CTE to enhance data contained in silver layer
	SELECT
		-- Select everything from silver layer
		pd.*,
		-- Create a 0/1 column for balls
		CASE
			WHEN pitch_result_short = 'B' THEN 1
			ELSE 0
		END AS ball,
		-- Create a 0/1 column to be able to count swinging strikes
		CASE
			-- First focus on only strikes
			WHEN pitch_result_short = 'S' THEN
				CASE
					-- 1 only if the description of the strike contains the word "swing"
					WHEN pitch_result_description LIKE 'swing%' THEN 1
					ELSE 0
				END
			ELSE 0
		END AS swinging_strike,
		-- Create 0/1 column to identify and counts "whiffs"
		CASE
			-- whiff is all swinging strikes and foul tips so we identify pitches descriptions containing those words
			WHEN pitch_result_description LIKE '%swinging_strike%' OR pitch_result_description LIKE '%foul_tip%' THEN 1
			ELSE 0
		END AS whiff,
		-- Create a 0/1 column for called strikes
		CASE
			WHEN pitch_result_short = 'S' THEN
				CASE
					-- Called strikes are all strikes that are not swing strikes and not fouled pitches
					WHEN pitch_result_description LIKE 'swing%' OR pitch_result_description LIKE '%foul%' THEN 0
					ELSE 1
				END
			ELSE 0
		END AS called_strike,
		-- Create a 0/1 column to identify and count plate appearances resulting in a strikeout
		CASE
			WHEN pitch_event LIKE 'strikeout%' THEN 1
			ELSE 0
		END AS strikeout,
		-- Create a 0/1 column to identify and count plate appearances resulting in a hit by pitch
		CASE 
			WHEN pitch_result_description = 'hit_by_pitch' THEN 1
			ELSE 0
		END AS hit_by_pitch,
		-- Create a 0/1 column to identify and count plate appearances resulting in a walk
		CASE 
			WHEN pitch_event LIKE '%walk' THEN 1
			ELSE 0
		END AS walk,
		-- Create a 0/1 column to identify and count plate appearances resulting in a ball hit in play
		CASE
			WHEN pitch_result_short = 'X' THEN 1
			ELSE 0
		END AS in_play,
		-- Create a 0/1 column to identify and count plate appearances resulting in a sacrifice hit
		CASE
			WHEN pitch_event LIKE '%sac%' THEN 1
			ELSE 0
		END AS sacrifice,
		-- Create a 0/1 column to identify and count plate appearances resulting in a sacrifice fly
		CASE
			WHEN pitch_event LIKE '%sac_fly%' THEN 1
			ELSE 0
		END AS sac_fly,
		-- Create a 0/1 column to identify and count plate appearances resulting in a single
		CASE
			WHEN pitch_event = 'single' THEN 1
			ELSE 0
		END AS single,
		-- Create a 0/1 column to identify and count plate appearances resulting in a double
		CASE
			WHEN pitch_event = 'double' THEN 1
			ELSE 0
		END AS double_,
		-- Create a 0/1 column to identify and count plate appearances resulting in a triple
		CASE
			WHEN pitch_event = 'triple' THEN 1
			ELSE 0
		END AS triple,
		-- Create a 0/1 column to identify and count plate appearances resulting in a home run
		CASE
			WHEN pitch_event = 'home_run' THEN 1
			ELSE 0
		END AS home_run,
		-- Create a 0/1 column to identify and count plate appearances resulting in a hit
		CASE
			WHEN pitch_event IN ('single', 'double', 'triple', 'home_run') THEN 1
			ELSE 0
		END AS hit,
		-- Create a column to have a string with the inning number and 'Extras' instead of the inning number if the games goes to
		-- extra innings
		CASE
			WHEN inning < 10 THEN CAST(inning AS VARCHAR)
			ELSE 'Extras'
		END AS inning_extras,
		-- Create a flag to identify the pitch ending the PA, using the window function ROW_NUMBER, and partitioning by game_id AND 
		-- at bat number. The ORDER BY is set up so that the last pitch of the PA will always have the number 1
		ROW_NUMBER() OVER (PARTITION BY pd.game_id, pd.at_bat_number ORDER BY pd.pitch_number DESC) AS flag_last_pitch_pa
	FROM silver.game_statcast_data AS pd
)

SELECT
	-- Final select and enhancement from CTEs
	*,
	-- Create column to refine the identification of swings, which are all pitches excluding called strikes, balls and hit by pitch
	CASE
		WHEN called_strike = 1 OR ball = 1 OR hit_by_pitch = 1 THEN 0
		ELSE 1
	END AS swing,
	-- Create column to distinguish at bats from plate appearances. At bats are all appearances resulting in a strikeout, ball in play
	-- or a sacrifice
	CASE
		WHEN strikeout = 1 THEN 1
		WHEN in_play = 1 THEN
			CASE
				WHEN sacrifice = 0 THEN 1
				ELSE 0
			END
		ELSE 0
	END AS at_bat
FROM CTE_enhanced_data