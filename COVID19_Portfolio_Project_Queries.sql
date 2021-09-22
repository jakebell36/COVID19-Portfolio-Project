 -- look at deaths data
SELECT * 
FROM Portfolio_Project.dbo.CovidDeaths
ORDER BY 3, 4;

-- look at vaccination data
SELECT * 
FROM Portfolio_Project.dbo.CovidVaccinations
ORDER BY 3, 4;

-- select data that we will be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths
ORDER BY 1,2;

-- look at total cases vs. total deaths for United States
-- shows likelihood of death if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Portfolio_Project..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

-- look at total cases vs. population
-- shows what percentage of population got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS CasePopulationPercentage
FROM Portfolio_Project..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

-- look at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) as highest_infected, 
	MAX((total_cases/population))*100 AS percent_population_infected
FROM Portfolio_Project..CovidDeaths
WHERE location like '%states%'
GROUP BY location, population
ORDER BY 4 DESC

-- show countries with highest death count per population. typecast total_deaths as an integer. Remove continent/global ones
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count desc 


-- LETS BREAK THINGS DOWN BY CONTINENT
-- Showing the continents with the highest death counts
SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count desc 


--This is more accurate data, but may mess with future visualizations
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM Portfolio_Project..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY total_death_count desc 

-- GLOBAL NUMBERS
-- Show total new cases, new deaths, and death percentage per day globally
SELECT date, SUM(new_cases) as world_new_cases, SUM(cast(new_deaths as int)) as world_new_deaths, 
	SUM( cast(new_deaths as int) ) / SUM(new_cases)*100 as new_cases_death_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--collapse values into total cases, total deaths, and total death percentage by removing "date" and the "GROUP BY date"
SELECT SUM(new_cases) as world_new_cases, SUM(cast(new_deaths as int)) as world_new_deaths, 
	SUM( cast(new_deaths as int) ) / SUM(new_cases)*100 as new_cases_death_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


-- Quick look at CovidVaccinations table
SELECT *
FROM Portfolio_Project..CovidVaccinations
ORDER BY iso_code

-- Join the 2 tables together to look at Total Population vs. Vaccinations
-- Make a running total column for vaccinations, for every country with -> SUM(...) OVER (PARTITION BY ..)



-- Use CTE

WITH pop_vs_vac ( continent, location, date, population, new_vaccinations, rolling_total_vaccinations) 
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_total_vaccinations
	--	, (rolling_total_vaccinations/population)*100
	FROM Portfolio_Project..CovidDeaths dea
	JOIN Portfolio_Project..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3
)
SELECT *, (rolling_total_vaccinations/population)*100 as percent_pop_vaccinated
FROM pop_vs_vac

-- TEMP table
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
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_total_vaccinations
	--	, (rolling_total_vaccinations/population)*100
	FROM Portfolio_Project..CovidDeaths dea
	JOIN Portfolio_Project..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3

SELECT *, (rolling_total_vaccinations/Population)*100
FROM #percent_population_vaccinated

-- Creating view to store data for later visualizations
CREATE VIEW Percent_Population_Vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_total_vaccinations
	--	, (rolling_total_vaccinations/population)*100
	FROM Portfolio_Project..CovidDeaths dea
	JOIN Portfolio_Project..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3

SELECT *
FROM percent_population_vaccinated;





CREATE VIEW usa_view AS
SELECT continent, location, date, population, total_deaths
FROM Portfolio_Project..CovidDeaths
WHERE location = 'United States';

SELECT *
FROM usa_view;