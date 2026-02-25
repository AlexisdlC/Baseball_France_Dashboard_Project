# Introduction

⚾ The goal of this project is to build a global baseball data dashboard using Power BI, and relying on data stored in a database built in SQL and updated semi-automatically using a python script. 

🐍 The data used in this project was obtained using the [PyBaseball](https://github.com/jldbc/pybaseball/tree/master/pybaseball) and the [MLB Stats API](https://github.com/toddrob99/MLB-StatsAPI/issues) packages in python. The data is not stored in intermediate .csv files ; it is pulled, pre-transformed and directly inserted in the SQL databse using the SQLAlechemy toolkit.

🌎 The project contains all MLB data, here for the 2025 regular season, but it can easily be adapted to collect and update as the 2026 season goes, for example. The dashboard is kept mostly in French, since the goal is to provide visuals and a platform for French baseball content creators to have access to polished statistics to share with their communities, tailored to the team they follow.

# Background

🏟️ Passionate about data, baseball and especially about the Yankees, I wanted to take the opportunity to join my two passions and use baseball statistics to practice and train my skills in building a proper data pipeline. This project expands on two other projects: [Yankees Overall Data Project](https://github.com/AlexisdlC/SQL_Yankees_Data/tree/main) and [Yankees Pitch Data Project](https://github.com/AlexisdlC/SQL_Yankees_Pitch_Statcast_Data/tree/main),  which focused on global statistics of Yankee players in Yankee games. With this project, I wanted to expand to larger datasets, for which pitch-by-pitch data is perfect.

### My main goals with this project:

* Build a database gathering global MLB pitch by pitch data and boxscore data using SQL. 📊
* Automate the data gathering and insertion into the SQL database using a Python script. ⚙️
* Build interactive dashboards to explore different aspects of the data in PowerBI. 📉
* Share my work with others, especially the French baseball community.
* Develop my skills in data analytics tools, using larger datasets, building best practice habits, and working towards the automation of the database update.

### Who Am I?

My name is **Alexis** and I am a Physics PhD with a passion for Data and Baseball. I am also on Twitter behind the account @PinstripesFr, where I provide news, updates, visuals and analysis about the New York Yankees in French. Don't hesitate to contact me if you have questions, ideas or suggestions!

[![text](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/alexisdlc/)
[![text](https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/PinstripesFr)

# Tools I Used

To develop this project, I used three main tools:

* **Python**: I used Python in order to query the MLB API through the [PyBaseball](https://github.com/jldbc/pybaseball/tree/master/pybaseball) and [MLB Stats API](https://github.com/toddrob99/MLB-StatsAPI/issues) packages, gather and pre-process the data. The script uses SQLAlchemy to connect to a SQL database and checks if the database is up-to-date before loading new data into the first layer of the database.
* **SQL**: Then, I used SQL to build a simple data warehouse with multiple layers to process, transform and clean the tables.
* **Power BI**: Finally, I loaded the database final layer into PowerBI and used Power Query and Dax to build several pages of an interactive dashboard allowing users to explore the data in different ways. The Power BI file is provided in the repository.

# Python Scripts

The repository contains three python files covering the data gathering and uploading in the SQL database.

* **functions.py**: collection of functions that are called and used in the main scripts. The functions are used to pull game, team and players' data from the MLB API.
* **initial_db_load.py**: Python script to do an initial load of data in the SQL database. The script pulls all stacast data between two hard coded dates that can be modified on line #12. From there it uses the funtions from _functions.py_ to get and transform the rest of the games and players data. After this, it connects to a local SQL database, and the parameters of the connection, to select for example which database to connect to, can be modified in section 7.1 of the code (lines #45-47). The script then proceeds to check the connection with the database and uploads data to the _bronze_ layer. 
**Important Notes**:
  1. The database needs to exist and has to have been created prior to running the script. This can be done using the _init_db.sql_ script.
  2. Running this script will completely replace the _bronze_ layer with the new data. If you already have data in the database, it'll be erased since the load is set to "if_exists = 'replace'". Only run for a first load, or if you want to restart from scractch. Otherwise use the _update_db.py_ script.
* **update_db.py**: Python script to update and load new data in the SQL database. The script first connects to the local database, using parameters that can be modified in section 1.1 (lines #18-20). After checking the connection, the script will query the database to check the latest game date already present and use it as the _start_date_ from which to start and pull data from. The user defined _end_date_ can be set in section 3 (line #71), and a safeguard will first check if the _end_date_ is after the _start_date_, since the Pybaseball function will automatically invert the dates to pull data. If the _end_date_ is before the _start_date_ the script will exit and no data will be added to the database to avoid duplicate entries. Otherwise the script will get the new data and use the functions from _functions.py_ to get and transform games and players' data. After this, it'll load the new data in the _bronze_ layer of the database, this time using the _"if_exists='append'"_ method to add new data and not reset the layer completely. Once all the tables of the _bronze_ layer have been updated, the script will also execute a stored procedure _silver.load_silver_ to push the new data to the silver layer, which will automatically be accessible in the gold layers which uses views.

# Data Warehouse Structure

The Data Warehouse was built in SQL using *SQL Server*, and in the *"Medaillon Structure"*.

## Bronze Layer

The **_Bronze Layer_** is used to load the unprocessed data from the source. This is the layer the Python scripts connect to, to load new data and update the database. The data is stored in tables.

## Silver Layer

The **_Silver Layer_** is used to store clean, processed and transformed data. The data is loaded using the *"Truncate and Insert"* method from the Bronze Layer. The data is stored in tables, cleaned, normalized, enriched and standardized.

## Gold Layer

The **_Gold Layer_** is the final layer of the Data Warehouse, with ready to use data for reporting and analytics. The data is stored in Views, with a Star Schema Model.

![Architecture of the model of the Gold Layer](/assets/DataMarts_Structure.drawio.png)

# Dashboards

The dashboards were built by connecting and loading the **_Gold Layer_** to **Power BI**. Power Query was used to transform some of the data (translating some terms to French, adding team logos and player pictures for example) and DAX was used as well to build Measures allowing for a responsive experience.

The dashboard can be accessed online here: [Access Dashboard](https://tinyurl.com/BaseballFr2025).

## "Vue Globale Equipe"

!["Vue Globale Equipe" Page](/assets/VueGlobaleEquipe.PNG)

This page of the dashboard presents global view of a team's players' statistics. The page is split in three sections:

* **Top**: Two slicers are present, one to select a team, one to adjust the date range. Next to this, the global win record, home win record and away win record will appear, as well as a line graph showing the win % evolution over the selected period. Note: if no team is selected, the table will have all the players in the league.
* **Center**: The first table presents batter statistics: basic cumulative stats, averages, and some advanced metrics. By default, batters are ranked by descending Run Value.
* **Bottom**: The second table presents pitcher statistics: basic cumulative stats, averages, and some advanced metrics. By default, pitchers are ranked by descending Run Value.

## "Stats Semaines Equipes"

!["Stats Semaines Equipes" Page](/assets/StatsSemainesEquipes.PNG)

This page of the dashboard shows the weekly evolution of team statistics. The team can be selected at the top of the page and the data is presented in different sections:

* **Batting Stats**: The first row of visuals presents team batting stats. The left column chart plots the weekly evolution of averages (BA, OBP, SLG, ...), overlayed with the weekly win percentage of the team. The plotted average can be selected from a slicer above the graph. On the right, another column chart shows the weekly evolution of cumulative stats (H, HR, R, ...) and which statistic is displayed can be chosen from the slicer above the graph.
*  **Pitching Stats**: The second row of visuals shows team pitching stats. The left column chart can be used to plot the weekly evolution of a selected average (ERA, WHIP, %K, ...) selected from a slicer above the chart. The right column chart plots cumulative statistics (K, ER, BB, ...), also selected using the slicer above the graph.

## "Résultats du Jour"

!["Résultats du Jour" Page](/assets/RésultatsJour.PNG)

This page of the dashboard shows the daily game results across all MLB. 

* **Calendar and Day Selection**: At the top of the page, there are two slicers: one to select a month of the year, a second to select a day of the month.
* **Result Table**: The main content of the page is a table presenting the game results for the selected day. The results are presented in the format: Home Team - Score - Away Team
* **Drill Through Option**: When clicking on a row/game in the table, a drill-through button activates at the top of the table, and upon clicking it, the user is taken to a game details' page:

!["Détails du Match" Page](/assets/DetailsMatch.PNG)

On this page, the score of the game is repeated at the top of the page, and the page is then split in several quadrants. First, we find a row with matrices presenting the batting boxscore of each team, and below each matrix, there is a scatter plot overlayed with a baseball field to show each team's hit locations. **Note**: the hit locations are just indicative and do not correspond with the exact location of the hit, since the baseball field overlayed with the location plot is not tailored to each ballpark, but is a simple standard ballpark. Below this is the pitching box score for each team, with finally, below each table, the pitch location of each major event of the game.
**Note**: this game details page can also be previewed by simply hovering the game in the table.

## "Les Leaders du Jour"

!["Leaders du Jour" Page](/assets/LeadersJour.PNG)

This page of the dashboard shows the daily leaders in selected statistics.

* **Calendar and Day Selection**: At the top of the page, there are two slicers: one to select a month of the year, a second to select a day of the month.
* **Batting Stats**: Two tables present leaders (top 5) in two batting statistics for the selected day: exit velocity (in mph) and home run hit distance (in ft).
* **Pitching Stats**: Two tables present leaders (top 5) in two pitching statistics for the selected day: pitch release speed (in mph) and whiff percentage.
