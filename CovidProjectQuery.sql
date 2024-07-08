SELECT *
FROM PortfolioProject..CovidDeathsCleaned
ORDER BY 3, 4

SELECT *
FROM PortfolioProject..CovidVaccinaitonsCleaned
ORDER BY 3, 4

--SELECT NEEDED DATA

SELECT TOP 50 location, CAST(date AS DATE), CAST(total_cases AS FLOAT), CAST(new_cases AS FLOAT), CAST(total_deaths AS FLOAT), CAST(population AS FLOAT)
FROM PortfolioProject..CovidDeathsCleaned
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths,
	CASE
		WHEN total_cases = 0 THEN 0
		ELSE (total_deaths/total_cases)*100
	END AS death_pctg
FROM (
	SELECT location, CAST (date AS DATE) as date, CAST(total_cases AS FLOAT) as total_cases, CAST(total_deaths AS FLOAT) as total_deaths
	FROM PortfolioProject..CovidDeathsCleaned) AS sq
ORDER BY 1, 2


-- Looking at Total Cases vs Population
-- Shows what percentage of population contracted COVID-19

SELECT location, date, population, total_cases,
	CASE
		WHEN population = 0 THEN 0
		ELSE (total_cases/population)*100
	END AS contraction_pctg
FROM (
	SELECT location, CAST (date AS DATE) as date, CAST(total_cases AS FLOAT) as total_cases, CAST(population AS FLOAT) as population
	FROM PortfolioProject..CovidDeathsCleaned) AS sq
ORDER BY 1, 2;


--Looking at countries with the highest infection rate compared to population

SELECT location, MAX(total_cases) as max_case_count, MAX(population) as avg_population,
	CASE
		WHEN MAX(population) = 0 THEN 0
		ELSE (MAX(total_cases)/MAX(population))*100
	END AS percentage_pop_infected
FROM (
	SELECT location, CAST(total_cases AS FLOAT) as total_cases, CAST(population AS FLOAT) as population
	FROM PortfolioProject..CovidDeathsCleaned) AS sq
	GROUP BY location
	ORDER BY 4 DESC


--Looking at countries with the highest death rate compared to population

SELECT location, MAX(total_deaths) as total_death_count, MAX(population) as population,
	CASE
		WHEN MAX(population) = 0 THEN 0
		ELSE (MAX(total_deaths)/MAX(population))*100
	END AS percentage_pop_died
FROM (
	SELECT location, CAST(total_deaths AS FLOAT) as total_deaths, CAST(population AS FLOAT) as population
	FROM PortfolioProject..CovidDeathsCleaned
	WHERE continent != '') AS sq
	GROUP BY location
	ORDER BY 2 DESC

--Breaking it down by Continent

SELECT continent, MAX(total_deaths) as total_death_count, MAX(population) as population,
	CASE
		WHEN MAX(population) = 0 THEN 0
		ELSE (MAX(total_deaths)/MAX(population))*100
	END AS percentage_pop_died
FROM (
	SELECT continent, location, CAST(total_deaths AS FLOAT) as total_deaths, CAST(population AS FLOAT) as population
	FROM PortfolioProject..CovidDeathsCleaned
	WHERE continent != '') AS sq
	GROUP BY continent
	ORDER BY 2 DESC


-- GLOBAL NUMBERS

--total deaths globally

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
	CASE
		WHEN SUM(new_deaths) = 0 THEN 0
		ELSE (SUM(new_deaths)/SUM(new_cases))*100 
	END AS death_percentage
FROM (
	SELECT CAST (date AS DATE) as date, CAST (new_cases AS FLOAT) as new_cases, CAST (new_deaths AS FLOAT) as new_deaths
	FROM PortfolioProject..CovidDeathsCleaned) AS sq


-- total cases and total deaths globally, by date

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths
FROM (
	SELECT CAST (date AS DATE) as date, CAST (new_cases AS FLOAT) as new_cases, CAST (new_deaths AS FLOAT) as new_deaths
	FROM PortfolioProject..CovidDeathsCleaned) AS sq
GROUP BY date
ORDER BY 1


-- percentage of global deaths by date

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
	CASE
		WHEN SUM(new_deaths) = 0 THEN 0
		ELSE (SUM(new_deaths)/SUM(new_cases))*100 
	END AS death_percentage
FROM (
	SELECT CAST (date AS DATE) as date, CAST (new_cases AS FLOAT) as new_cases, CAST (new_deaths AS FLOAT) as new_deaths
	FROM PortfolioProject..CovidDeathsCleaned) AS sq
GROUP BY date
ORDER BY 1

-- calculating rolling vaccination count

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, new_vaccinations, SUM(CAST(vax.new_vaccinations AS FLOAT)) 
	OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeathsCleaned AS deaths
JOIN PortfolioProject..CovidVaccinationsCleaned AS vax
	 ON deaths.location = vax.location 
	 AND deaths.date = vax.date
WHERE deaths.continent != ''
ORDER BY 2, 3


--calculating the number of vaccinations vs population

WITH pop_vs_vax (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, new_vaccinations, SUM(CAST(vax.new_vaccinations AS FLOAT)) 
	OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeathsCleaned AS deaths
JOIN PortfolioProject..CovidVaccinationsCleaned AS vax
	 ON deaths.location = vax.location 
	 AND deaths.date = vax.date
WHERE deaths.continent != ''
)
SELECT *, 
	CASE
		WHEN population = 0 THEN 0
		ELSE (rolling_vaccinations/population)*100
	END AS vax_percentage
FROM pop_vs_vax
ORDER BY 2,3

-- TEMP TABLE
DROP TABLE IF EXISTS #pop_vs_vax
CREATE TABLE #pop_vs_vax
(
continent nvarchar(255),
location nvarchar(255),
date date,
population float,
new_vaccinations float,
rolling_vaccinations float
)

INSERT INTO #pop_vs_vax
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, new_vaccinations, SUM(CAST(vax.new_vaccinations AS FLOAT)) 
	OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeathsCleaned AS deaths
JOIN PortfolioProject..CovidVaccinationsCleaned AS vax
	 ON deaths.location = vax.location 
	 AND deaths.date = vax.date
WHERE deaths.continent != ''

SELECT *, 
	CASE
		WHEN population = 0 THEN 0
		ELSE (rolling_vaccinations/population)*100
	END AS vax_percentage
FROM #pop_vs_vax
ORDER BY 2,3




--Creating view to show total percentage of population vaccinated

USE PortfolioProject
GO
CREATE VIEW percent_population_vaxxed AS 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, new_vaccinations, SUM(CAST(vax.new_vaccinations AS FLOAT)) 
	OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeathsCleaned AS deaths
JOIN PortfolioProject..CovidVaccinationsCleaned AS vax
	 ON deaths.location = vax.location 
	 AND deaths.date = vax.date
WHERE deaths.continent != ''


SELECT *
FROM percent_population_vaxxed


--Creating view to show total percentage of cases resulted in deaths

USE PortfolioProject
GO
CREATE VIEW deaths_vs_cases AS
SELECT location, date, total_cases, total_deaths,
	CASE
		WHEN total_cases = 0 THEN 0
		ELSE (total_deaths/total_cases)*100
	END AS death_pctg
FROM (
	SELECT location, CAST (date AS DATE) as date, CAST(total_cases AS FLOAT) as total_cases, CAST(total_deaths AS FLOAT) as total_deaths
	FROM PortfolioProject..CovidDeathsCleaned) AS sq


-- creating a view to show oercentage of population infected

USE PortfolioProject
GO
CREATE VIEW percentage_population_infected AS
SELECT location, date, population, total_cases,
	CASE
		WHEN population = 0 THEN 0
		ELSE (total_cases/population)*100
	END AS contraction_pctg
FROM (
	SELECT location, CAST (date AS DATE) as date, CAST(total_cases AS FLOAT) as total_cases, CAST(population AS FLOAT) as population
	FROM PortfolioProject..CovidDeathsCleaned) AS sq


--View showing the total deaths by cointinent

USE PortfolioProject
GO
CREATE VIEW deaths_by_continent AS
SELECT continent, MAX(total_deaths) as total_death_count, MAX(population) as population,
	CASE
		WHEN MAX(population) = 0 THEN 0
		ELSE (MAX(total_deaths)/MAX(population))*100
	END AS percentage_pop_died
FROM (
	SELECT continent, location, CAST(total_deaths AS FLOAT) as total_deaths, CAST(population AS FLOAT) as population
	FROM PortfolioProject..CovidDeathsCleaned
	WHERE continent != '') AS sq
	GROUP BY continent
	
