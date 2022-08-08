SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3, 4

-- SELECT *
-- FROM PortfolioProject..CovidVax
-- ORDER BY 3, 4

-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2

-- Looking at total cases vs total deaths
-- likelihood you die if you contract covid in your country
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2


-- total cases vs population
SELECT location, date, total_cases, new_cases, population, (total_cases/population)*100 AS cases_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'malaysia'
ORDER BY 1, 2

-- country with highest infection rate compared to population
SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX((total_cases/population)*100) AS population_infected_percentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY population_infected_percentage DESC

-- country with highest death count per population
SELECT location, MAX(cast(total_deaths as bigint)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC
-- we will see some grouping by continents which we dont want

-- let's break things down by continent
SELECT continent, MAX(cast(total_deaths as bigint)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- global numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as bigint)) AS total_deaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- looking at total population vs vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinations
-- cumulative sum
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVax v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2, 3

-- use CTE
-- need to make sure that the number of columns in the CTE is the same as the number of clumns in the SELECT section
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinations
-- cumulative sum
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVax v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
-- ORDER BY 2, 3
)

SELECT *, (rolling_vaccinations/population)*100 AS percentage_vaccinated
FROM pop_vs_vac


-- temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_vaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinations
-- cumulative sum
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVax v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
-- ORDER BY 2, 3

SELECT *, (rolling_vaccinations/population)*100 AS percentage_vaccinated
FROM #PercentPopulationVaccinated

-- creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(cast(v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinations
-- cumulative sum
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVax v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
-- ORDER BY 2, 3
