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
