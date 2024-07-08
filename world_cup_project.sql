SELECT *
FROM WorldCupProject..fifa_ranking
ORDER BY 1

SELECT *
FROM WorldCupProject..matches
ORDER BY date desc

SELECT *
FROM WorldCupProject..world_cup
ORDER BY 1


--Finding WC wins by association
-- This query joins the world_cup and fifa_rankings tables. The world_cup table has the champion data and the fifa_rankings table has the association data
--The group by function here has combines the rows based on the champion team's association
-- Those rows are then counted in the SELECT clause, thus returning the number of WC wins by association

SELECT rank.association, COUNT(*) AS wins_by_assoc
FROM WorldCupProject..fifa_ranking AS rank
JOIN WorldCupProject..world_cup AS cup
ON rank.team = cup.champion
GROUP BY rank.association;



--Showing average attendance at all WCs since 1930

SELECT Year, (Attendance/Matches) as AverageAttendance
FROM WorldCupProject..world_cup
ORDER BY 1


-- Finding the # of goals per WC
--This query includes a sub-query to perform aggregate functions that can than be used for fuurther calculations in the outer-query

SELECT Year, Host, home_goals+away_goals as total_goals, home_penalties+away_penalties as total_penalties
FROM (
	SELECT Year, Host, SUM(home_score) as home_goals, SUM(away_score) as away_goals, SUM(home_penalty) as home_penalties, SUM(away_penalty) as away_penalties
	FROM WorldCupProject..matches
	GROUP BY Year, Host) AS sq
	ORDER BY 1


--Total goals per team through all WCs


SELECT team, sum(total_goals) as total_goals
	FROM(
		SELECT home_score AS total_goals, home_team AS team 
		FROM WorldCupProject..matches
		UNION ALL 
		SELECT away_score AS total_goals, away_team AS team
		FROM WorldCupProject..matches) AS sq
GROUP BY team
ORDER BY 2 DESC




--Total Goals per team (2018 - 2022)

SELECT team, sum(total_goals) as total_goals
	FROM(
		SELECT home_score AS total_goals, home_team AS team 
		FROM WorldCupProject..matches
		WHERE Date > '2018-01-01'
		UNION ALL 
		SELECT away_score AS total_goals, away_team AS team
		FROM WorldCupProject..matches
		WHERE Date > '2018-01-01') AS sq
GROUP BY team
ORDER BY 2 DESC


-- total xG per team in the 2018 and 2022 WCs (xG was calulated starting in 2018)
-- Unionize both xG columns (home and away) as well has team columns (home and away)
--Sum xG and d group by Team


SELECT team, sum(xg)
	FROM(
		SELECT home_xg AS xg, home_team AS team 
		FROM WorldCupProject..matches
		WHERE Date > '2018-01-01'
		UNION ALL 
		SELECT away_xg AS xg, away_team AS team
		FROM WorldCupProject..matches
		WHERE Date > '2018-01-01') AS sq
GROUP BY team
ORDER BY 2 DESC