/* ====================================================================
CRIAR A BASE DE DADOS
(se não houver já uma com esse nome) 
==================================================================== */
CREATE DATABASE IF NOT EXISTS topleagues;
USE topleagues;

/* ====================================================================
CRIAR AS TABELAS QUE VÃO RECEBER OS DADOS 
Os nomes das tabelas e dos campos correspondem aos nomes das tabelas
e colunas nos ficheiros .csv
Importante criar as tabelas por esta ordem, para evitar criar tabelas
com foreign keys a referenciar tabelas que ainda não existem
==================================================================== */
-- 1. Treinadores
CREATE TABLE IF NOT EXISTS coaches (
    coach_id INT PRIMARY KEY,
    name VARCHAR(50),
    team_id INT,
    nationality VARCHAR(50)
);

-- 2. Ligas
CREATE TABLE IF NOT EXISTS leagues (
    league_id INT PRIMARY KEY,
    name VARCHAR(30),
    country VARCHAR(50),
    country_id INT,
    icon_url VARCHAR(100),
    cl_spot INT,
    uel_spot INT,
    relegation_spot INT
);

-- 3. Estádios
CREATE TABLE IF NOT EXISTS stadiums (
    stadium_id INT PRIMARY KEY,
    name VARCHAR(100),
    location VARCHAR(200),
    capacity INT
);

-- 4. Épocas
CREATE TABLE IF NOT EXISTS seasons (
    season_id INT PRIMARY KEY,
    league_id INT,
    year VARCHAR(20),
    FOREIGN KEY (league_id) REFERENCES leagues(league_id)
);

-- 5. Equipas
CREATE TABLE IF NOT EXISTS teams (
    team_id INT PRIMARY KEY,
    name VARCHAR(100),
    founded_year INT,
    stadium_id INT,
    league_id INT,
    coach_id INT,
    cresturl VARCHAR(100),
    FOREIGN KEY (stadium_id) REFERENCES stadiums(stadium_id),
    FOREIGN KEY (league_id) REFERENCES leagues(league_id),
    FOREIGN KEY (coach_id) REFERENCES coaches(coach_id)
);

-- 6. Jogadores
CREATE TABLE IF NOT EXISTS players (
    player_id INT PRIMARY KEY,
    team_id INT,
    name VARCHAR(50),
    position VARCHAR(20),
    date_of_birth DATE,
    nationality VARCHAR(50),
    FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

-- 7. Árbitros
CREATE TABLE IF NOT EXISTS referees (
    referee_id INT PRIMARY KEY,
    name VARCHAR(50),
    nationality VARCHAR(50)
);

-- 8. Jogos
CREATE TABLE IF NOT EXISTS matches (
    match_id INT PRIMARY KEY,
    season_id INT,
    league_id INT,
    matchday INT,
    home_team_id INT,
    away_team_id INT,
    winner VARCHAR(20),
    `utc_date` DATE,  -- necessário as `` para permitir criar uma coluna com este nome
    FOREIGN KEY (season_id) REFERENCES seasons(season_id),
    FOREIGN KEY (league_id) REFERENCES leagues(league_id),
    FOREIGN KEY (home_team_id) REFERENCES teams(team_id),
    FOREIGN KEY (away_team_id) REFERENCES teams(team_id)
);

-- 9. Resultados
CREATE TABLE IF NOT EXISTS scores (
    score_id INT PRIMARY KEY,
    match_id INT,
    full_time_home INT,
    full_time_away INT,
    half_time_home INT,
    half_time_away INT,
    FOREIGN KEY (match_id) REFERENCES matches(match_id)
);

-- 10. Classificações
CREATE TABLE IF NOT EXISTS standings (
    standing_id INT PRIMARY KEY,
    season_id INT,
    league_id INT,
    position INT,
    team_id INT,
    played_games INT,
    won INT,
    draw INT,
    lost INT,
	points INT,
    goals_for INT,
    goals_against INT,
    goal_difference INT,
    form VARCHAR(50),
    FOREIGN KEY (season_id) REFERENCES seasons(season_id),
    FOREIGN KEY (league_id) REFERENCES leagues(league_id),
    FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

/* ====================================================================
CARREGAR DADOS
Inserir linhas dos ficheiros .csv nas tabelas criadas.

A forma mais simples que consegui utilizar para inserir os dados foi
começar por correr a linha abaixo, que fornece uma localização segura
para os ficheiros e permite correr as linhas seguintes.

Se o caminho retornado não for:
'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\'
então é necessário alterar a parte inicial do caminho em todos os
blocos de código abaixo, e depois copiar a pasta kaggle_dataset para
esse caminho.
==================================================================== */
SHOW VARIABLES LIKE 'secure_file_priv';

-- 1. Treinadores
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/coaches.csv'
INTO TABLE coaches
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 2. Ligas
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/leagues.csv'
INTO TABLE leagues
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 3. Estádios
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/stadiums.csv'
INTO TABLE stadiums
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(stadium_id, name, location, @cap)
SET capacity = NULLIF(@cap, '');

-- 4. Épocas
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/seasons.csv'
INTO TABLE seasons
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 5. Equipas
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/teams.csv'
INTO TABLE teams
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(team_id, name, @founded_year, stadium_id, league_id, coach_id, cresturl)
SET founded_year = NULLIF(@founded_year,'');

-- 6. Jogadores
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/players.csv'
INTO TABLE players
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 7. Árbitros
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/referees.csv'
INTO TABLE referees
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 8. Jogos
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/matches.csv'
INTO TABLE matches
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 9. Resultados
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/scores.csv'
INTO TABLE scores
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 10. Classificações
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/kaggle_dataset/standings.csv'
INTO TABLE standings
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/* ====================================================================
VALIDAR INSERÇÃO

Verificar se todas as tabelas parecem ter os dados bem inseridos
==================================================================== */
SELECT * FROM coaches;
SELECT * FROM leagues;
SELECT * FROM stadiums;
SELECT * FROM seasons;
SELECT * FROM teams;
SELECT * FROM players;
SELECT * FROM referees;
SELECT * FROM matches;
SELECT * FROM scores;
SELECT * FROM standings;

/* ====================================================================
EXPLORAR

A partir daqui, já podemos utilizar os dados à vontade e explorar
a base de dados.
Como teste, vamos experimentar os exemplos disponibilizados na página
do dataset no Kaggle:
https://www.kaggle.com/datasets/kamrangayibov/football-data-european-top-5-leagues
==================================================================== */
-- 1. Retornar todos os jogos de uma equipa específica
SELECT m.*, t1.name as home_team, t2.name as away_team
FROM matches m
JOIN teams t1 ON m.home_team_id = t1.team_id
JOIN teams t2 ON m.away_team_id = t2.team_id
WHERE t1.team_id = 1 OR t2.team_id = 2;

-- A query retorna todos os jogos em casa do '1. FC Köln' e todos os
-- jogos fora do 'TSG 1899 Hoffenheim'.

-- 2. Obter a classificação mais recente:
SELECT t.name, s.*
FROM standings s
JOIN teams t ON s.team_id = t.team_id
WHERE s.league_id = 1
ORDER BY s.points DESC;

-- A query devolve a classificação final da Premier League.

-- 3. Obter os melhores marcadores (comentado para não dar erro):
/*
SELECT p.name, p.team_id, COUNT(*) as goals
FROM scores s
JOIN players p ON s.scorer_id = p.player_id
GROUP BY p.player_id, p.name, p.team_id
ORDER BY goals DESC;
*/

/*
Parece faltar uma coluna a indicar os marcadores dos golos (talvez
a estrutura ideal da tabela scores não fosse a atual).

Ainda assim, estes dados permitem entrar em detalhe sobre os jogos
das 5 principais ligas europeias e desenvolver análises a
diferentes níveis, podem servir como base para experimentação e
criação de projetos individuais.
*/