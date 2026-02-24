import numpy as np
import pandas as pd
import statsapi
import pybaseball as pb
from datetime import date, datetime, timedelta
from tqdm.auto import tqdm
import re

# 1. Define function to get game data for a list of game ids

def get_game_data(game_ids_list):
    out = []

    for g_id in tqdm(game_ids_list):
        result = statsapi.schedule(game_id=g_id)
        if len(result) > 1:
          for r in result:
            if not (r['status'] == 'Postponed' or r['status'] == 'Cancelled'):
              out.append(r)
        else:
          out.append(result[0])
    return pd.DataFrame(out).drop(columns=['home_pitcher_note','away_pitcher_note', 'national_broadcasts', 'summary'])

# 2. Define function to get team data for a list of team ids

def get_team_data(team_ids_list):
    out = []

    for t in tqdm(team_ids_list):
        result = statsapi.lookup_team(t, activeStatus="B")

        out.append(result[0])
    return pd.DataFrame(out)

# 3. Define function to get batter boxscore from a single game_id and a list of game ids

def game_analysis_batter(game_id):
  
  ## Get full boxscore data for the game and extract the home and away team ids.

  game_data = statsapi.boxscore_data(game_id)

  home_id = game_data['teamInfo']['home']['id']
  away_id = game_data['teamInfo']['away']['id']

  ## Get home and away batter data, and add columns for hbp and sf (since those are not included in the boxscore data, but are important for calculating plate appearances)

  home_batters = pd.DataFrame(game_data['homeBatters'])
  home_batters['hbp'] = 0
  home_batters['sf'] = 0

  away_batters = pd.DataFrame(game_data['awayBatters'])
  away_batters['hbp'] = 0
  away_batters['sf'] = 0

  ## Get boxscore info data, and use it to extract the hbp and sf that happened in the game.

  gameBoxInfo = pd.DataFrame(game_data['gameBoxInfo'])
  try:
    hbp_string = gameBoxInfo[gameBoxInfo['label'] == 'HBP']['value'].to_list()[0]
    hbp_list = hbp_string.split(';')
  except:
    hbp_string = ''

  home_teamBoxInfo = pd.DataFrame(game_data['home']['info'][0]['fieldList'])
  try:
    home_sf_string = home_teamBoxInfo[home_teamBoxInfo['label'] == 'SF']['value'].to_list()[0]
  except:
    home_sf_string = ''

  away_teamBoxInfo = pd.DataFrame(game_data['away']['info'][0]['fieldList'])
  try:
    away_sf_string = away_teamBoxInfo[away_teamBoxInfo['label'] == 'SF']['value'].to_list()[0]
  except:
    away_sf_string = ''

## Loop through the home batters

  for index, row in home_batters.iterrows():
    ## Check if batter is present in hbp string. If yes, check number of hbp and add it to dataframe.
    if row['name'] in hbp_string:
      for s in hbp_list:
        if row['name'] in s:
          digit_test = any(char.isdigit() for char in s)
          if digit_test:
            home_batters.at[index,'hbp'] = int(re.findall(r"\d+\.?\d*", s)[0])
          else:
            home_batters.at[index,'hbp'] = 1
        ## Check if batter is present in sf string. If yes, add 1 sf to dataframe.
        if row['name'] in home_sf_string:
          home_batters.at[index,'sf'] = 1

## Loop through the away batters and do the same as what was done for the home batters

  for index, row in away_batters.iterrows():
    if row['name'] in hbp_string:
      for s in hbp_list:
        if row['name'] in s:
          digit_test = any(char.isdigit() for char in s)
          if digit_test:
            away_batters.at[index,'hbp'] = int(re.findall(r"\d+\.?\d*", s)[0])
          else:
            away_batters.at[index,'hbp'] = 1
        if row['name'] in away_sf_string:
          away_batters.at[index,'sf'] = 1

## Filter home and away batters data.
  home_batters_filter = home_batters[home_batters['personId'] != 0][['personId','ab','r','h','doubles','triples','hr','rbi','sb','bb','k','hbp','sf']]
  home_batters_filter['gameId'] = game_id
  home_batters_filter['team_id'] = home_id

  away_batters_filter = away_batters[away_batters['personId'] != 0][['personId','ab','r','h','doubles','triples','hr','rbi','sb','bb','k','hbp','sf']]
  away_batters_filter['gameId'] = game_id
  away_batters_filter['team_id'] = away_id

  return pd.concat([home_batters_filter,away_batters_filter])

## Function to get batting boxscore data from a list of game ids.

def game_list_analysis_batting(game_ids_list):

    for i,x in enumerate(tqdm(game_ids_list)):
      
      result = game_analysis_batter(x)

      if i == 0:
        final = result.copy()
      else:
        final = pd.concat([final,result])

    return final.astype(float)

# 3. Define function to get pitcher boxscore from a single game_id and a list of game ids

def game_analysis_pitching(game_id):

    ## Get full boxscore data for the game and extract the home and away team ids.

    game_data = statsapi.boxscore_data(game_id)

    home_id = game_data['teamInfo']['home']['id']
    away_id = game_data['teamInfo']['away']['id']

    ## Get home and away pitcher data, and add columns for hbp and batters faced.

    home_pitchers = pd.DataFrame(game_data['homePitchers'])
    home_pitchers['hbp'] = 0
    home_pitchers['bat_faced'] = 0

    away_pitchers = pd.DataFrame(game_data['awayPitchers'])
    away_pitchers['hbp'] = 0
    away_pitchers['bat_faced'] = 0

    ## Get boxscore info data, and use it to extract the hbp and batters faced that happened in the game.

    gameBoxInfo = pd.DataFrame(game_data['gameBoxInfo'])

    try:
        hbp_string = gameBoxInfo[gameBoxInfo['label'] == 'HBP']['value'].to_list()[0]
        hbp_list = hbp_string.split(';')
    except:
        hbp_string = ''

    battersFaced = gameBoxInfo[gameBoxInfo['label'] == 'Batters faced']['value'].to_list()[0]
    battersFaced_list = battersFaced.split(';')

    ## Loop through the home pitchers

    for index, row in home_pitchers.iterrows():
      ## Check if pitcher is present in hbp string. If yes, check number of hbp and add it to dataframe.
      if row['name'] in hbp_string:
        home_pitchers.at[index,'hbp'] = hbp_string.count(row['name'])
        ## Check if pitcher is present in batters faced string. If yes, check number of batters faced and add it to dataframe.
      for s in battersFaced_list:
        if row['name'] in s:
          home_pitchers.at[index,'bat_faced'] = int(re.findall(r"\d+", s)[0])
    
    ## Loop through the away pitchers and do the same as what was done for the home pitchers

    for index, row in away_pitchers.iterrows():
      if row['name'] in hbp_string:
        away_pitchers.at[index,'hbp'] = hbp_string.count(row['name'])

      for s in battersFaced_list:
        if row['name'] in s:
          away_pitchers.at[index,'bat_faced'] = int(re.findall(r"\d+", s)[0])

    ## Filter home and away pitchers data. We also calculate the number of outs recorded by the pitcher using the number of innings pitched (ip)

    home_pitchers_filter = home_pitchers[home_pitchers['personId'] != 0][['personId','ip','h','r','er','bb','k','hr','p','s','hbp','bat_faced',]]
    home_pitchers_filter['gameId'] = game_id
    home_pitchers_filter['team_id'] = home_id
    home_pitchers_filter = home_pitchers_filter.astype(float)
    home_pitchers_filter['outs'] = 3*home_pitchers_filter['ip'].astype(int) + 10*(home_pitchers_filter['ip'] - home_pitchers_filter['ip'].astype(int))

    away_pitchers_filter = away_pitchers[away_pitchers['personId'] != 0][['personId','ip','h','r','er','bb','k','hr','p','s','hbp','bat_faced',]]
    away_pitchers_filter['gameId'] = game_id
    away_pitchers_filter['team_id'] = away_id
    away_pitchers_filter = away_pitchers_filter.astype(float)
    away_pitchers_filter['outs'] = 3*away_pitchers_filter['ip'].astype(int) + 10*(away_pitchers_filter['ip'] - away_pitchers_filter['ip'].astype(int))


    return pd.concat([home_pitchers_filter,away_pitchers_filter])


## Function to get pitching boxscore data from a list of game ids.
def game_list_analysis_pitching(game_ids_list):

    for i,x in enumerate(tqdm(game_ids_list)):
      
      result = game_analysis_pitching(x)

      if i == 0:
        final = result.copy()
      else:
        final = pd.concat([final,result])

    return final.astype(float)