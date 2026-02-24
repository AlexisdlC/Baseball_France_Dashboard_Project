import numpy as np
import pandas as pd
import statsapi
import pybaseball as pb
from datetime import date, datetime, timedelta
from tqdm.auto import tqdm
from functions import get_game_data, get_team_data, game_analysis_batter, game_analysis_pitching, game_list_analysis_batting, game_list_analysis_pitching
import re
import sys

# 1. Connect to Microsoft SQL Server DB

from sqlalchemy import create_engine, event, text
import urllib

# 1.1 Define connection parameters

server_name = 'DESKTOP-5C6OGPG\SQLEXPRESS01'
database_name = 'BaseballFrTest'
driver = 'ODBC+Driver+17+for+SQL+Server'

# 1.2 Create the connection string
# This format handles spaces and special characters safely
params = urllib.parse.quote_plus(
    f'DRIVER={{{driver}}};'
    f'SERVER={server_name};'
    f'DATABASE={database_name};'
    f'Trusted_Connection=yes;'
    f'TrustServerCertificate=yes;'
)

connection_string = f"mssql+pyodbc:///?odbc_connect={params}"

# 1.3 Create the engine
engine = create_engine(connection_string)

# 1.4 Test the connection
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

# 2. Get the date of the last entry in the database.

with engine.connect() as connection:
    result = connection.execute(text("SELECT MAX(game_date) FROM bronze.game_statcast_data"))
    last_date = result.scalar()

print(f"Latest record in database: {last_date}")

# 3. Define end_date and start date for new data pull from pybaseball.

last_date_adj = pd.to_datetime(last_date) + timedelta(days=1)
start_date = last_date_adj.strftime('%Y-%m-%d')
#end_date = datetime.today().strftime('%Y-%m-%d')
end_date = '2025-09-28' # For testing purposes, since we don't want to pull a lot of new data right now.

# 3.1 Check if start_date is in the future. If it is, exit the script since there's no new data to pull.

if start_date > end_date:
    print(f"Start date {start_date} is greater than end date {end_date}. No new data to pull. Exiting script.")
    sys.exit()  

# 4. Pull new data from pybaseball.

print(f"Pulling new data from {start_date} to {end_date}...")
df = pb.statcast(start_dt=start_date,end_dt=end_date)
df_filtered = df[df['game_type'].isin(['R', 'F', 'D', 'L', 'W'])]

# 5. Extract game ids, batter ids, and pitcher ids from the new data.

game_ids = list(set(df_filtered.game_pk.to_list()))
batter_ids = list(set(df_filtered.batter.to_list()))
pitcher_ids = list(set(df_filtered.pitcher.to_list()))

# 6. Get the game data from statsapi

game_df = get_game_data(game_ids)

# 7. Get the new batter and pitcher data

# 7.1 Get batter and pitcher ids already present in the database

query_batters = """
SELECT DISTINCT batter AS player_id FROM bronze.game_statcast_data
"""

query_pitchers = """
SELECT DISTINCT pitcher AS player_id FROM bronze.game_statcast_data
"""

with engine.connect() as connection:
    unique_batter_ids_df = pd.read_sql(text(query_batters), connection)
    unique_pitcher_ids_df = pd.read_sql(text(query_pitchers), connection)

# Convert to a simple Python list if needed
batter_ids_in_db = unique_batter_ids_df['player_id'].tolist()
pitcher_ids_in_db = unique_pitcher_ids_df['player_id'].tolist()

# 7.2 Filter the new batter and pitcher ids to only include those not already in the database

new_batter_ids = [b for b in batter_ids if b not in batter_ids_in_db]
new_pitcher_ids = [p for p in pitcher_ids if p not in pitcher_ids_in_db]

# 7.3 Pull the new batter and pitcher data from pybaseball

if len(new_batter_ids) > 0:
    batters_df = pb.playerid_reverse_lookup(new_batter_ids)
if len(new_pitcher_ids) > 0:
    pitchers_df = pb.playerid_reverse_lookup(new_pitcher_ids)

# 8. Get the boxscore data for each game, batting and pitching.

batting_boxscore_df = game_list_analysis_batting(game_ids)
pitching_boxscore_df = game_list_analysis_pitching(game_ids)

# 9. Send the new data to the database.

# 9.1 Send statcast data

with engine.begin() as connection:
    df_filtered.to_sql('game_statcast_data',
            con=engine,
            schema='bronze',
            if_exists='append',
            index=False, 
            chunksize=None
)

# 9.2 Send game data
with engine.begin() as connection:
    game_df.to_sql('game_data',
            con=engine,
            schema='bronze',
            if_exists='append',
            index=False, 
            chunksize=None
)
    
# 9.3 Send boxscore data
with engine.begin() as connection:
    batting_boxscore_df.to_sql('batting_boxscore_data',
            con=engine,
            schema='bronze',
            if_exists='append',
            index=False, 
            chunksize=None
)
    
with engine.begin() as connection:
    pitching_boxscore_df.to_sql('pitching_boxscore_data',
            con=engine,
            schema='bronze',
            if_exists='append',
            index=False, 
            chunksize=None
)
    
# 9.4 Send new player data (only those not already in the database)

if len(new_batter_ids) > 0:
    with engine.begin() as connection:
        batters_df.to_sql('batters_data',
            con=engine,
            schema='bronze',
            if_exists='append',
            index=False, 
            chunksize=None
)
        
if len(new_pitcher_ids) > 0:
    with engine.begin() as connection:
        pitchers_df.to_sql('pitchers_data',
            con=engine,
            schema='bronze',
            if_exists='append',
            index=False, 
            chunksize=None
)
        
print("✅ Bronze load complete.")

# 10. Run the Silver stored procedure 
# # We use EXEC for SQL Server
with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as connection:
    connection.execute(text("EXEC silver.load_silver"))
    # This forces Python to wait until the SQL Server says "I'm totally done"
    connection.commit()

print("✅ Silver load complete.")