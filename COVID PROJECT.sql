/*
Data is retrived from https://ourworldindata.org/covid-deaths

SELECT * 
FROM CovidDeaths
ORDER BY 3,4;

SELECT * 
FROM CovidVaccinations
ORDER BY 3,4;*/

-- Select data that we're gonna be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths.
-- Shows the percentage chance of dying if you get covid in USA
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%Belarus%' 
AND continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of the population got Covid
SELECT location, date, total_cases, population, (total_cases / population)*100 as InfectedPercentage
FROM CovidDeaths
WHERE location LIKE '%Belarus%' 
AND continent is not null
ORDER BY 1,2

-- Looking at country infection rate compared to population
SELECT location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases / population))*100 as InfectedPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY InfectedPercentage DESC

-- Showing countries with the highest death count
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC



-- LET'S BREAK IT DOWN BY CONTINENT

-- Showing continents with the highest death count
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Looking at continent infection rate
SELECT continent, MAX(total_cases) as HighestInfectionCount, MAX((total_cases / population))*100 as InfectedPercentageOfPopulation
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY InfectedPercentageOfPopulation DESC



-- GLOBAL NUMBERS of Total Cases, Total Deaths by date
SELECT date, SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, (SUM(new_deaths) / SUM(new_cases))*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2



-- Looking at total population vs vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, SUM(vax.new_vaccinations) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated--, (TotalPeopleVaccinated/population)*100
FROM CovidDeaths as dea
JOIN CovidVaccinations as vax
ON dea.location = vax.location
AND dea.date = vax.date
WHERE dea.continent is not null
ORDER BY 2, 3

-- USE CTE
WITH PopVax (continent, location, date, population, new_vaccinations, TotalPeopleVaccinated) AS (

    SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, SUM(vax.new_vaccinations) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated--, (TotalPeopleVaccinated/population)*100
    FROM CovidDeaths as dea
    JOIN CovidVaccinations as vax
    ON dea.location = vax.location
    AND dea.date = vax.date
    WHERE dea.continent is not null
    --ORDER BY 2, 3

)
SELECT *, (TotalPeopleVaccinated / population)*100
FROM PopVax

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255), 
date datetime,
population numeric,
new_vaccinations numeric,
TotalPeopleVaccinated numeric
)
 
INSERT INTO #PercentPopulationVaccinated
    SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, SUM(vax.new_vaccinations) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated--, (TotalPeopleVaccinated/population)*100
    FROM CovidDeaths as dea
    JOIN CovidVaccinations as vax
    ON dea.location = vax.location
    AND dea.date = vax.date
    WHERE dea.continent is not null
    --ORDER BY 2, 3

SELECT *, (TotalPeopleVaccinated / population)*100
FROM #PercentPopulationVaccinated



-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
    SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, SUM(vax.new_vaccinations) 
    OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as TotalPeopleVaccinated--, (TotalPeopleVaccinated/population)*100
    FROM CovidDeaths as dea
    JOIN CovidVaccinations as vax
    ON dea.location = vax.location
    AND dea.date = vax.date
    WHERE dea.continent is not null
--    ORDER BY 2, 3

SELECT * 
FROM PercentPopulationVaccinated



-- QUERIES FOR TABLEAU PROJECT

-- Overview of total cases, deaths, and percentage of deaths
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_Cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Death rate by continent
SELECT location, MAX(total_deaths)*100/MAX(total_cases) as TotalDeathRate
FROM CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International', 'Low income', 'Lower middle income', 'High income', 'Upper middle income')
GROUP BY location
ORDER BY TotalDeathRate DESC

-- overview of highest infection rates
SELECT location, population, MAX(total_cases) as HighestInfectionCount,  MAX(total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Same as previous but grouping by date
SELECT location, population, date, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC
