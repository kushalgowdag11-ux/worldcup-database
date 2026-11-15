#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Create a temporary table to hold the CSV data
SQL="CREATE TEMP TABLE games_import (
  year INT,
  round VARCHAR(60),
  winner VARCHAR(60),
  opponent VARCHAR(60),
  winner_goals INT,
  opponent_goals INT
);"

# Read the CSV file
while IFS="," read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # Skip the header row
  if [[ "$YEAR" != "year" && -n "$YEAR" ]]
  then
    SQL+=" INSERT INTO games_import VALUES (
      $YEAR,
      '$ROUND',
      '$WINNER',
      '$OPPONENT',
      $WINNER_GOALS,
      $OPPONENT_GOALS
    );"
  fi
done < games.csv

# Insert unique teams
SQL+="
INSERT INTO teams(name)
SELECT team_name
FROM (
  SELECT winner AS team_name FROM games_import
  UNION
  SELECT opponent AS team_name FROM games_import
) AS all_teams
ON CONFLICT(name) DO NOTHING;

"

# Insert games with the correct team IDs
SQL+="
INSERT INTO games(
  year,
  round,
  winner_id,
  opponent_id,
  winner_goals,
  opponent_goals
)
SELECT
  g.year,
  g.round,
  w.team_id,
  o.team_id,
  g.winner_goals,
  g.opponent_goals
FROM games_import g
JOIN teams w ON g.winner = w.name
JOIN teams o ON g.opponent = o.name;
"

# Execute all SQL commands
$PSQL "$SQL"
