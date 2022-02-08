--Using Microsoft SQL Server Management Studio
SELECT *
FROM PortfolioProject..CovidDeaths;

SELECT *
FROM Portfolioproject..CovidVaccinations;

-- Select data that I am going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

--Looking at total cases vs total deaths
--Shows potential of dying if you contract COVID in the US
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2;

-- Looking at total cases vs population in US
SELECT location, date, population, total_cases, (total_cases/population)*100 AS Percent_of_cases_in_US
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2;

--Looking at countries that have highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS Highest_infection_count, MAX((total_cases/population))*100 AS Percent_of_population_infected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC;

--Looking at country with highest death count
--Pulled continent data in location column when continent column showed as NULL
SELECT location, MAX(cast(total_deaths as int)) AS Total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;

--Looking at continent with highest death count
SELECT continent, MAX(cast(total_deaths as int)) AS Total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

--Global numbers
SELECT date, SUM(new_cases) AS Total_cases, SUM(cast(new_deaths as int)) AS Death_count, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

--Join with vaccination numbers
SELECT *
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date;

--Tracking amount of doses given each day and in total in US
SELECT d.location, d.date, d.population, v.new_vaccinations AS doses_given_on_day, SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS total_number_doses_given 
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
AND d.location = 'United States'
ORDER BY 2;

--Finding percentage of US population fully vaccinated as of 01-25-2022
SELECT d.location, d.date, d.population, v.people_fully_vaccinated, (v.people_fully_vaccinated/d.population)*100 AS percent_in_US_fully_vaccinated
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
AND d.location = 'United States'
ORDER BY 2;

--Finding percentage that is fully vaccinted and has taken booster in US
WITH VacBoost AS (SELECT d.location, d.date, d.population, v.people_fully_vaccinated, (v.people_fully_vaccinated/d.population)*100 AS percent_in_US_fully_vaccinated, (v.total_boosters/d.population)*100 AS percent_in_US_boosted
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
AND d.location = 'United States')

SELECT *, (percent_in_US_boosted/percent_in_US_fully_vaccinated)*100 AS percent_of_vaccinated_with_booster
FROM VacBoost
ORDER BY date;

--Comparing the US with the rest of the locations in the dataset.
--Noticed continents pulling in to location data and found that if the continent column showed N/A it pulled the continent itself through in the locations tab
WITH VacBoost AS (SELECT d.location, d.date, d.population, v.people_fully_vaccinated, (v.people_fully_vaccinated/d.population)*100 AS percent_fully_vaccinated, (v.total_boosters/d.population)*100 AS percent_boosted
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL)

SELECT *, (percent_boosted/percent_fully_vaccinated)*100 AS percent_of_vaccinated_with_booster
FROM VacBoost
ORDER BY location, date;

--Looking for totals in locations as of January 23 2022. Data is scattered and some data for locations hasnt been filled in for months so I am using MAX to find the time it was reported with the highest amount because that should give us the most recent total.
WITH VacBoost AS (SELECT d.location, d.date, d.population, v.people_fully_vaccinated, (v.people_fully_vaccinated/d.population)*100 AS percent_fully_vaccinated, (v.total_boosters/d.population)*100 AS percent_boosted
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL)

SELECT location, MAX(percent_fully_vaccinated) AS percent_fully_vaccinated, MAX(percent_boosted) AS percent_of_pop_boosted, MAX((percent_boosted/percent_fully_vaccinated)*100) AS percent_of_vaccinated_with_booster
FROM VacBoost
GROUP BY location
ORDER BY location;

--Scrolled down and realized Eritrea, Marshall Islands, Micronesia, Northern Cyprus, Palau, Saint Pierre, Vatican are all showing NULL. Looking to find out why.
SELECT d.location, MAX(d.population) AS pop, MAX(v.people_fully_vaccinated) AS full_vac
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
GROUP BY d.location
HAVING MAX(d.population) IS  NULL
	OR MAX(v.people_fully_vaccinated) IS NULL
ORDER BY 2;

--Eritrea, Marshall Islands, Micronesia, Northern Cyprus, Palau, Saint Pierre are all NULL due to no reporting on people being fully vaccinated. Northern Cyprus has fully vaccinated numbers, but no population.
--Looked it up online and Northern Cyprus is only recognised by Turkey, but Turkey facilitates its contacts with the international community so that is why I am assuming the numbers on here because they are the ones recording the data for that portion of Cyprus.
--Going to look at anything containing Cyprus in the name for location to compare with population data online.
SELECT d.location, MAX(d.population) AS pop, MAX(v.people_fully_vaccinated) AS full_vac
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.location LIKE '%Cyprus%'
GROUP BY d.location
ORDER BY 2;

--According to UN data for January 25th 2022 the current population fo Cyprus is 1,230,273 those number dont add up with the data so I am assuming that the population for Northern Cyprus data is the UN estimate minus the Cyprus reported data.
--That gives them a population of...
SELECT 1230273 - 896005 AS population_of_NorthernCyprus
--334,268 which is roughly the answer that I could find online.

--Looking to add population to the tables for Northern Cyprus. Only need to add it to CovidDeaths, since CovidVaccinations doesn't have that column.
UPDATE PortfolioProject..CovidDeaths
SET population = 334268
WHERE location = 'Northern Cyprus';

--Checking to make sure it worked
SELECT d.location, MAX(d.population) AS pop, MAX(v.people_fully_vaccinated) AS full_vac
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.location LIKE '%Cyprus%'
GROUP BY d.location
ORDER BY 2;
--Worked

--Going to create visualizations based on the following.
--Percent of fully vaccinated population of the world.
--Percent of fully vaccinated and boostered of the world.
--Using the below as the data source for the visualization

WITH VacBoost AS (SELECT d.location, d.date, d.population, v.people_fully_vaccinated, (v.people_fully_vaccinated/d.population)*100 AS percent_fully_vaccinated, (v.total_boosters/d.population)*100 AS percent_boosted
FROM PortfolioProject..CovidDeaths AS d
JOIN PortfolioProject..CovidVaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL)

SELECT location, MAX(percent_fully_vaccinated) AS percent_fully_vaccinated, MAX(percent_boosted) AS percent_of_pop_boosted, MAX((percent_boosted/percent_fully_vaccinated)*100) AS percent_of_vaccinated_with_booster
FROM VacBoost
GROUP BY location
ORDER BY location;