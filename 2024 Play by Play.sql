USE [NBA Play by Play]



--All Data
SELECT *
FROM plays24



--Top 10 regular season scorers
SELECT 
    player, 
    SUM(points) AS total_points
FROM plays24
WHERE data_set IN ('NBA 2023-2024 Regular Season', 'NBA 2023 In-Season Tournament')
GROUP BY player
ORDER BY total_points DESC;



--Number of times each team got to the free throw line from the regular season
SELECT
    team,
    SUM(CASE WHEN event_type = 'free throw' THEN num ELSE 0 END) AS total_free_throws
FROM plays24
WHERE data_set IN ('NBA 2023-2024 Regular Season', 'NBA 2023 In-Season Tournament')
GROUP BY team
ORDER BY total_free_throws DESC;



--All players to score 800+ points and grab 700+ rebounds in the regular season
SELECT player, 
       SUM(points) AS total_points,
       SUM(CASE WHEN event_type = 'rebound' THEN 1 ELSE 0 END) AS total_rebounds
FROM plays24
WHERE data_set IN ('NBA 2023-2024 Regular Season', 'NBA 2023 In-Season Tournament')
GROUP BY player
HAVING SUM(points) >= 800 AND SUM(CASE WHEN event_type = 'rebound' THEN 1 ELSE 0 END) >= 700;



--Teams to call most total timeouts from the regular season
SELECT 
    team,
    COUNT(*) AS total_timeouts
FROM plays24
WHERE event_type = 'timeout'
  AND data_set IN ('NBA 2023-2024 Regular Season', 'NBA 2023 In-Season Tournament')
GROUP BY team
ORDER BY total_timeouts DESC;



--Average total points scored after each quarter from the regular season
SELECT 
    period,
    ROUND(AVG(away_score + home_score), 2) AS avg_combined_score
FROM plays24
WHERE event_type = 'end of period'
  AND data_set IN ('NBA 2023-2024 Regular Season', 'NBA 2023 In-Season Tournament')
GROUP BY period
HAVING period IN (1, 2, 3, 4)
ORDER BY period;



--Top scoring / assisting duos from regular season
SELECT
       scorer,
       assister,
       COUNT(*) AS field_goals_made
FROM (
    SELECT player AS scorer,
           assist AS assister
    FROM plays24
    WHERE event_type = 'shot'
      AND assist IS NOT NULL
      AND data_set IN ('NBA 2023-2024 Regular Season', 'NBA 2023 In-Season Tournament')
) AS scoring_assists
GROUP BY scorer, assister
ORDER BY field_goals_made DESC;



--Top 5 most points scored in a playoff game by an individual player
WITH GamePoints AS (
    SELECT
        player,
        game_id,
        SUM(points) AS total_points_in_game
    FROM plays24
    WHERE data_set = 'NBA 2024 Playoffs'
    GROUP BY player, game_id
)
SELECT TOP 5
    player,
    MAX(total_points_in_game) AS max_points_in_a_single_game
FROM GamePoints
GROUP BY player
ORDER BY max_points_in_a_single_game DESC;



--Longest made shots from the regular season
WITH PlayerLongestShot AS (
    SELECT 
        player,
        date,
        description,
        shot_distance,
        ROW_NUMBER() OVER (PARTITION BY player ORDER BY shot_distance DESC) AS shot_rank
    FROM plays24
    WHERE event_type = 'shot'
      AND result = 'made'
      AND data_set IN ('NBA 2023-2024 Regular Season', 'NBA 2023 In-Season Tournament')
)
SELECT 
    player,
    date,
    description,
    shot_distance AS shot_distance
FROM PlayerLongestShot
WHERE shot_rank = 1
ORDER BY shot_distance DESC;



--Players who averaged most points per game in the 4th quarter during the playoffs
WITH PlayerStats AS (
    SELECT 
        player,
        SUM(points) AS total_points,
        COUNT(DISTINCT game_id) AS games_played,
        ROUND(CAST(SUM(points) AS FLOAT) / COUNT(DISTINCT game_id), 2) AS avg_points_per_game
    FROM plays24
    WHERE period = 4
      AND data_set = 'NBA 2024 Playoffs'
    GROUP BY player
)
SELECT 
    player,
    total_points,
    games_played,
    avg_points_per_game
FROM PlayerStats
ORDER BY avg_points_per_game DESC;



--Top players with highest proportion of shots taken being a 3-pointer during regular season (min 65 games played)
WITH PlayerStats AS (
    SELECT 
        player,
        COUNT(*) AS total_shots,
        SUM(CASE WHEN type LIKE '%3pt%' THEN 1 ELSE 0 END) AS three_point_shots,
        COUNT(DISTINCT game_id) AS games_played
    FROM plays24
    WHERE event_type = 'shot'
      AND data_set IN ('NBA 2023-2024 Regular Season', 'NBA 2023 In-Season Tournament')
    GROUP BY player
)
SELECT 
    player,
    three_point_shots,
    total_shots,
    ROUND(CAST(three_point_shots AS FLOAT) / total_shots, 2) AS three_point_percentage
FROM PlayerStats
WHERE games_played >= 65
ORDER BY three_point_percentage DESC;





