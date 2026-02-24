import numpy as np
import pandas as pd
import statsapi
import pybaseball as pb
from datetime import date, datetime, timedelta
from tqdm.auto import tqdm
from functions import get_game_data, get_team_data, game_analysis_batter, game_analysis_pitching, game_list_analysis_batting, game_list_analysis_pitching
import re

# 1. Get the starter data from statcast

df = pb.statcast(start_dt='2025-03-18',end_dt='2025-04-15')
df_filtered = df[df['game_type'].isin(['R', 'F', 'D', 'L', 'W'])]

# 2. Extract game, batter, pitcher ids

game_ids = list(set(df_filtered.game_pk.to_list()))
batter_ids = list(set(df_filtered.batter.to_list()))
pitcher_ids = list(set(df_filtered.pitcher.to_list()))

# 3. Get the game data and player data from statsapi

game_df = get_game_data(game_ids)
batters_df = pb.playerid_reverse_lookup(batter_ids)
pitchers_df = pb.playerid_reverse_lookup(pitcher_ids)

# 5. Get the team_ids, define a function to get team data, and get the team data

team_ids = list(set(pd.concat([game_df.away_id,game_df.home_id]).to_list()))

teams_df = get_team_data(team_ids)

# 6. Get the boxscore data for each game, batting and pitching.

batting_boxscore_df = game_list_analysis_batting(game_ids)
pitching_boxscore_df = game_list_analysis_pitching(game_ids)

# 7. Connect to Microsoft SQL Server DB

from sqlalchemy import create_engine, event, text
import urllib

# 7.1 Define connection parameters

server_name = 'DESKTOP-5C6OGPG\SQLEXPRESS01'
database_name = 'BaseballFrTest'
driver = 'ODBC+Driver+17+for+SQL+Server'

# 7.2 Create the connection string
# This format handles spaces and special characters safely
params = urllib.parse.quote_plus(
    f'DRIVER={{{driver}}};'
    f'SERVER={server_name};'
    f'DATABASE={database_name};'
    f'Trusted_Connection=yes;'
    f'TrustServerCertificate=yes;'
)

connection_string = f"mssql+pyodbc:///?odbc_connect={params}"

# 7.3 Create the engine
engine = create_engine(connection_string)

# 7.4 Test the connection
try:
    with engine.connect() as connection:
        # Run a tiny SQL command to verify "active" communication
        result = connection.execute(text("SELECT 1")).scalar()
        
        if result == 1:
            print(f"✅ Active connection confirmed for: {database_name}")
            
            # Optional: Print the actual server version to see what caused the warning
            version = connection.execute(text("SELECT @@VERSION")).scalar()
            print(f"Connected to: {version.splitlines()[0]}")
            
except Exception as e:
    print(f"❌ Connection failed: {e}")

@event.listens_for(engine, "before_cursor_execute")
def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    if executemany:
        cursor.fast_executemany = True

# 8. Send data to SQL Server (This creates the table automatically if it doesn't exist)

# 8.1 Send statcast data
with engine.begin() as connection:
    df_filtered.to_sql('game_statcast_data',
            con=engine,
            schema='bronze',
            if_exists='replace',
            index=False, 
            chunksize=None
)

# 8.2 Send game data
with engine.begin() as connection:
    game_df.to_sql('game_data',
            con=engine,
            schema='bronze',
            if_exists='replace',
            index=False, 
            chunksize=None
)

# 8.3 Send player data
with engine.begin() as connection:
    batters_df.to_sql('batters_data',
            con=engine,
            schema='bronze',
            if_exists='replace',
            index=False, 
            chunksize=None
)

with engine.begin() as connection:
    pitchers_df.to_sql('pitchers_data',
            con=engine,
            schema='bronze',
            if_exists='replace',
            index=False, 
            chunksize=None
)

# 8.4 Send team data
with engine.begin() as connection:
    teams_df.to_sql('teams_data',
            con=engine,
            schema='bronze',
            if_exists='replace',
            index=False, 
            chunksize=None
)
    
# 8.5 Send boxscore data
with engine.begin() as connection:
    batting_boxscore_df.to_sql('batting_boxscore_data',
            con=engine,
            schema='bronze',
            if_exists='replace',
            index=False, 
            chunksize=None
)
    
with engine.begin() as connection:
    pitching_boxscore_df.to_sql('pitching_boxscore_data',
            con=engine,
            schema='bronze',
            if_exists='replace',
            index=False, 
            chunksize=None
)
    