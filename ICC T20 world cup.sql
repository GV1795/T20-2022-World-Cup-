SELECT *
FROM fact_bating_summary;
-----
select * 
from fact_bowling_summary
------
select* 
from dim_match_summary
-----
select * 
from dim_players
---- Total team
SELECT COUNT(DISTINCT[teamInnings]) AS TotalTeamsPlayed
FROM [dbo].[fact_bating_summary];

-- Top 3 Run scorer
SELECT 
    SUM(runs) AS TotalRuns,
    batsmanName
FROM 
    [dbo].[fact_bating_summary]
GROUP BY 
    batsmanName
ORDER BY 
    TotalRuns DESC
OFFSET 0 ROWS
FETCH NEXT 3 ROWS ONLY;

---- Top 3 Wicket Taker
SELECT 
    SUM(wickets) AS Totalwickets,
    bowlerName
FROM 
    [dbo].[fact_bowling_summary]
GROUP BY 
    bowlerName
ORDER BY 
    Totalwickets DESC
OFFSET 0 ROWS
FETCH NEXT 3 ROWS ONLY;

--- Total run
SELECT 
    SUM([runs]) AS TotalRuns
FROM 
   [dbo].[fact_bating_summary]

-- Top 5 Bowling Averge bowler name.
SELECT TOP 5
    bowlerName,
    SUM([runs]) AS TotalRunsConceded,
    SUM(Wickets) AS TotalWickets,
    CASE 
        WHEN SUM(Wickets) > 0 THEN CAST(SUM([runs]) AS FLOAT) / SUM(Wickets)
        ELSE 0
    END AS BowlingAverage
FROM 
    dbo.fact_bowling_summary
GROUP BY 
    bowlerName
ORDER BY 
    BowlingAverage DESC;

-- Total runs scored in the world cup.
	SELECT 
    FORMAT(SUM([runs]), '0') AS TotalRuns
FROM 
    [dbo].[fact_bating_summary];

-- Total dissmissal
SELECT 
    SUM(CASE WHEN [out_not_out]= 'out' THEN 1 ELSE 0 END) AS TotalInningsDismissed
FROM 
    [dbo].[fact_bating_summary]

-- Batting average.
SELECT 
    SUM([runs]) AS TotalRuns,
    SUM(CASE WHEN [out_not_out] = 'out' THEN 1 ELSE 0 END) AS TotalInningsDismissed,
    CASE 
        WHEN SUM(CASE WHEN [out_not_out] = 'out' THEN 1 ELSE 0 END) > 0 THEN CAST(SUM([runs]) AS FLOAT) / SUM(CASE WHEN out_not_out = 'out' THEN 1 ELSE 0 END)
        ELSE 0
    END AS BattingAverage
FROM 
    [dbo].[fact_bating_summary]


-- strike rate.
	SELECT 
    SUM([runs]) AS TotalRuns,
    SUM([balls]) AS TotalBallsFaced,
    CASE 
        WHEN SUM([balls]) > 0 THEN CAST(SUM([runs]) AS FLOAT) / SUM([balls]) * 100
        ELSE 0
    END AS StrikeRate
FROM 
    [dbo].[fact_bating_summary];


-- Boundry runs Percentage.
SELECT 
    SUM([_4s] + [_6s]) AS BoundaryRuns,
    SUM(runs) AS TotalRuns,
    CASE 
        WHEN SUM(runs) > 0 THEN CAST(SUM([_4s] + [_6s]) AS FLOAT) / SUM(runs) * 100
        ELSE 0
    END AS BoundaryPercentage
FROM 
    [dbo].[fact_bating_summary];
 
 -- Average ball faced.
  SELECT 
    AVG([balls]) AS AverageBallsFaced
FROM 
    [dbo].[fact_bating_summary]

-- Total balls faced.
SELECT 
    SUM([balls]) AS TotalBallsFaced
FROM 
    [dbo].[fact_bating_summary]

-- Overall total balls
SELECT 
    SUM(
        ROUND([overs], 0) * 6 +  -- Number of complete overs
        ROUND(([overs] - FLOOR([overs])) * 10, 0) +  -- Remaining balls (decimal part of overs)
        [maiden] + 
        [wides] + 
        [noBalls]
    ) AS OverallTotalBalls
FROM 
    [dbo].[fact_bowling_summary];

-- dot balls percentage.
SELECT 
    SUM([_0s]) * 100.0 / 
    CASE 
        WHEN SUM(
            ROUND([overs], 0) * 6 +  -- Number of complete overs
            ROUND(([overs] - FLOOR([overs])) * 10, 0) +  -- Remaining balls (decimal part of overs)
            [maiden] + 
            [wides] + 
            [noBalls]
        ) = 0 THEN NULL 
        ELSE SUM(
            ROUND([overs], 0) * 6 +  -- Number of complete overs
            ROUND(([overs] - FLOOR([overs])) * 10, 0) +  -- Remaining balls (decimal part of overs)
            [maiden] + 
            [wides] + 
            [noBalls]
        ) 
    END AS DotBallPercentage
FROM 
    [dbo].[fact_bowling_summary];

-- Overall economy during the worldcup.
	SELECT 
    CAST(SUM(runs) / SUM([overs]) AS INT) AS OverallEconomy
FROM 
    [dbo].[fact_bowling_summary];

	-- England was the winner.
SELECT TOP 1
    Winner AS WinningTeam,
    COUNT(*) AS TotalMatchesWon
FROM 
    dbo.dim_match_summary
GROUP BY 
    Winner
ORDER BY 
    TotalMatchesWon DESC;

-- Matches won by Team 1, and team 2
SELECT 
    MAX(CASE WHEN Winner = Team1 THEN Team1 ELSE Team2 END) AS Team,
    SUM(CASE WHEN Winner = Team1 THEN 1 ELSE 0 END) AS TotalMatchesWonByTeam1,
    SUM(CASE WHEN Winner = Team2 THEN 1 ELSE 0 END) AS TotalMatchesWonByTeam2
FROM 
    dbo.dim_match_summary
WHERE
    Winner IN (Team1, Team2)
GROUP BY 
    Team1, Team2;

-- summary of the matches won by team1 and team 2
WITH MatchCounts AS (
    SELECT 
        MAX(CASE WHEN Winner = Team1 THEN Team1 ELSE Team2 END) AS Team,
        SUM(CASE WHEN Winner = Team1 THEN 1 ELSE 0 END) AS TotalMatchesWonByTeam1,
        SUM(CASE WHEN Winner = Team2 THEN 1 ELSE 0 END) AS TotalMatchesWonByTeam2
    FROM 
        dbo.dim_match_summary
    WHERE
        Winner IN (Team1, Team2)
    GROUP BY 
        Team1, Team2
)

SELECT 
    SUM(TotalMatchesWonByTeam1) AS TotalMatchesWonByTeam1,
    SUM(TotalMatchesWonByTeam2) AS TotalMatchesWonByTeam2
FROM 
    MatchCounts;

-- maximum match won according to the ground.
SELECT ground, match_id, winner_count
FROM [dbo].[dim_match_summary]
JOIN (
    SELECT TOP 1 winner, COUNT(*) AS winner_count
    FROM [dbo].[dim_match_summary]
    WHERE winner IS NOT NULL
    GROUP BY winner
    ORDER BY COUNT(*) DESC
) AS max_winner
ON [dbo].[dim_match_summary].winner = max_winner.winner
ORDER BY match_id;










    
   













