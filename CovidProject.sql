--------- Covid-19 Project overview

------ Part 1
-- Dataset from https://ourworldindata.org/covid-deaths.
-- Divided dataset into two: 'CovidDeaths' and 'CovidVaccinations'.
-- Created database in Microsoft SQL Server 'CovidProject'.
-- Uploaded datasets.
-- Run queries: CovidProject.sql
-- Saved results in Excel files.

------ Part 2
-- Created dashboards in Tableau:
----- Covid Infections and Deaths - organized by continents, shows total counts and rates of infections and deaths, rates are calculated as (total count)/(population size)*100%
----- Covid Death Rates and Vaccinations - organized by countries, shows death rates for each country; Vaccine Shots/Population - how many vaccine shots were taken in each country in relation to it's population (%).
----- Covid Vaccines vs Population - shows how Vaccine Shots/Population changed over time for several countries. Additionaly forecast of this parameter is presented for each of selected countries.


--------- Part 1 - Data Exploration 

------ Exploring datasets
--- Covid Deaths

SELECT *
FROM CovidProject..CovidDeaths
WHERE continent is not null
ORDER BY 3, 4

--- Covid Vaccinations

SELECT *
FROM CovidProject..CovidVaccinations
WHERE continent is not null
ORDER BY 3, 4

------ Total cases vs total deaths
--- Likelihood of dying if you contract Covid in selected country day-by-day

SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location = 'Russia'
and continent is not null 
ORDER BY 1,2

--------------------------------------------------------------
------ Total cases vs population
--------------------------------------------------------------

---- Countries

--- Countries with highest Infection Counts

SELECT Location, population, MAX(total_cases) AS TotalInfections
FROM CovidProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 3 DESC

--- Countries with highest Infection Rates compared to population size

SELECT Location, Population, MAX(total_cases) AS TotalInfections,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

---- Continents

--- Continents with highest Infection Counts

SELECT continent, SUM(distinct population) AS TotalPopulation, MAX(cast(total_cases AS INT)) AS TotalInfections
FROM CovidProject..CovidDeaths
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalInfections DESC

--- Continents with highest Infection Rates compared to size of population

-- Used subquery in FROM clause to aggregate data by continent

SELECT continent, TotalPopulation, (TotalInfections/TotalPopulation)*100 AS InfectionRate
FROM 
(SELECT continent, sum(distinct population) as TotalPopulation, MAX(cast(total_cases AS INT)) AS TotalInfections
FROM CovidProject..CovidDeaths
WHERE continent is not null 
GROUP BY continent) as cont_infected
ORDER BY InfectionRate DESC

--------------------------------------------------------------
------ Total deaths vs population
--------------------------------------------------------------

---- Countries

--- Countries with highest Death Counts

SELECT Location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent is not null 
GROUP BY Location
ORDER BY TotalDeathCount DESC

--- Countries with highest Death Rates compared to population size

SELECT Location, population, MAX(cast(total_deaths AS INT)) AS TotalDeathCount, 
(sum(cast(new_deaths AS INT))/population)*100 AS DeathRate
FROM CovidProject..CovidDeaths
WHERE continent is not null 
GROUP BY Location, population
ORDER BY DeathRate DESC

---- Continents

--- Contintents with the highest Death Counts

SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount DESC

--- Contintents with the highest Death Rates compared to population size

-- Used subquery in FROM clause to aggregate data by continent

SELECT continent, TotalPopulation, TotalDeathCount, (TotalDeathCount/TotalPopulation)*100 AS DeathRate
FROM 
(SELECT continent, sum(distinct population) as TotalPopulation, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent is not null 
GROUP BY continent) as cont_deaths
ORDER BY DeathRate DESC

--------------------------------------------------------------
----- Deaths worldwide
--------------------------------------------------------------

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, 
SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2

--------------------------------------------------------------
------ Total population vs vaccinations
--------------------------------------------------------------

ALTER TABLE CovidProject..CovidVaccinations
ALTER COLUMN new_vaccinations numeric;
-- needed to avoid calculation arithmetic overflow later

--- Total numbers vaccine shots compared to population size

-- Day by day

With PopvsVac (Continent, Location, date, Population, New_Vaccinations, CountVaccines)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location Order by dea.location, dea.Date) AS CountVaccines
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT *, (CountVaccines/Population)*100 AS VaccinesvsPopulation
FROM PopvsVac

-- Total numbers

With PopvsVac (Continent, Location, date, Population, New_Vaccinations, CountVaccines)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location Order by dea.location, dea.Date) AS CountVaccines
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT location, max(CountVaccines) AS TotalVaccinesCount, max(population) AS PopulationSize, MAX(CountVaccines/Population)*100 AS VaccinesvsPopulation
FROM PopvsVac
GROUP BY location
ORDER BY VaccinesvsPopulation DESC


-- Creating View to store data for later visualizations

CREATE VIEW CountVaccines AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location Order by dea.location, dea.Date) AS CountVaccines
FROM CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
