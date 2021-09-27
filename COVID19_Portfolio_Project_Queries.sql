/* 
COVID-19 Data Exploration

Dataset used: https://ourworldindata.org/covid-deaths

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT * 
FROM Portfolio_Project.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3, 4


-- Select data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Total cases vs. Total deaths 
-- Shows likelihood of death if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM Portfolio_Project..CovidDeaths
WHERE location like '%states%'
AND continent is not null
ORDER BY 1,2


-- Total cases vs. Population
-- Shows what percentage of population infected with covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS case_population_percentage
FROM Portfolio_Project..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;


-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM Portfolio_Project..CovidDeaths
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY percent_population_infected DESC


-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count desc 


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count desc 



-- GLOBAL NUMBERS

-- Showing numbers for Total Cases, Total Deaths, and Death Percentage globally

SELECT SUM(new_cases) as world_total_cases, SUM(cast(new_deaths as int)) as world_total_deaths, 
	SUM( cast(new_deaths as int) ) / SUM(new_cases)*100 as world_death_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as rolling_total_vaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition by in the above query

WITH pop_vs_vac ( continent, location, date, population, new_vaccinations, rolling_total_vaccinated) 
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as rolling_total_vaccinated
	--, (RollingPeopleVaccinated/population)*100
	FROM Portfolio_Project..CovidDeaths dea
	JOIN Portfolio_Project..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null 
	--ORDER BY 2,3
)
SELECT *, (rolling_total_vaccinated/population)*100 as percent_pop_vaccinated
FROM pop_vs_vac



-- Using Temp Table to perform Calculation on Partition By in the above query


DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_total_vaccinations numeric
)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as rolling_total_vaccinated
	--, (RollingPeopleVaccinated/population)*100
	FROM Portfolio_Project..CovidDeaths dea
	JOIN Portfolio_Project..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null 
	--ORDER BY 2,3

SELECT *, (rolling_total_vaccinations/Population)*100
FROM #percent_population_vaccinated




-- Creating View to store data for later visualizations

CREATE VIEW Percent_Population_Vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as rolling_total_vaccinated
	--, (RollingPeopleVaccinated/population)*100
	FROM Portfolio_Project..CovidDeaths dea
	JOIN Portfolio_Project..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null 
	--ORDER BY 2,3

SELECT *, (rolling_total_vaccinations/population) * 100
FROM percent_population_vaccinated;


-- Creating a View of a specific country for later visualizations

CREATE VIEW usa_view AS
SELECT continent, location, date, population, total_deaths
FROM Portfolio_Project..CovidDeaths
WHERE location = 'United States';

SELECT *
FROM usa_view;
