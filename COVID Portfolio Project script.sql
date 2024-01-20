SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- Select Data that we are going to using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--looking at Total Cases vs Total Death (how many cases and death in the country)
--Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%malaysia%'
and continent IS NOT NULL
ORDER BY 1,2


--looking at Total Cases vs Population
--shows what percentage of population got covid

SELECT location, date, population, total_cases, (total_cases/population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malaysia%'
WHERE continent IS NOT NULL
ORDER BY 1,2

--looking at countries with Highest Infection Rate compared to Population
--(how many infected)

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malaysia%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC --Desc: Highest percent first 

--showing the country with the Highest Death Count Per Population

SELECT location,  MAX(cast(total_deaths AS int)) AS TotalDeathCount --coz total_deaths datatype in varchar (need to change into int datatype)
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malaysia%'
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC --Desc: Highest percent first 

--showing the continent with the Highest Death Count Per Population

SELECT continent,  MAX(cast(total_deaths AS int)) AS TotalDeathCount --coz total_deaths datatype in varchar (need to change into int datatype)
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malaysia%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC --Desc: Highest percent first 

--global numbers (death percentage globally across the world)

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malaysia%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--global numbers (death percentage globally across the world) --not include date (overall)
 
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%malaysia%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

SELECT *
FROM PortfolioProject..CovidVaccinations

--join CovidDeaths & CovidVaccinations table on location&date

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Looking at total population vs vacinnation

--Total vaccination for each country is counted but it show total end result
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location) --PARTITION BY LOCATION SO THAT IS ONLY FOR EACH COUNTRY and not added up for every country
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Total vaccination for each country is counted but it show counting process through date and location
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --PARTITION BY LOCATION SO THAT IS ONLY FOR EACH COUNTRY and not added up for every country
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --PARTITION BY LOCATION SO THAT IS ONLY FOR EACH COUNTRY and not added up for every country
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--Total vaccination for each country is counted but it show counting process through date and location (find out max total vacinnation using RollingPeople Vaccinated)
--cannot use "RollingPeopleVaccinated" straightaway -> need to use cte
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --PARTITION BY LOCATION SO THAT IS ONLY FOR EACH COUNTRY and not added up for every country
--,(RollingPeopleVaccinated/dea.population)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--use cte
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated) --need to be the same as select statement below
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --PARTITION BY LOCATION SO THAT IS ONLY FOR EACH COUNTRY and not added up for every country
--,(RollingPeopleVaccinated/dea.population)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


--SAME LIKE CTE BUT USING TEMP TABLE () 

DROP TABLE IF EXISTS #PercentPopulationVaccinated --cannot run temp table more than one so use this to drop temp table before run again

CREATE TABLE #PercentPopulationVaccinated --created table and insert data
(
Comtinent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

 INSERT INTO #PercentPopulationVaccinated
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --PARTITION BY LOCATION SO THAT IS ONLY FOR EACH COUNTRY and not added up for every country
--,(RollingPeopleVaccinated/dea.population)
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated
