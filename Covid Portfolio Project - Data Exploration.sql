-- Verify CovidDeaths table has been populated after import from .xlsx file

select *
from [PortfolioProject]..CovidDeaths
--where continent is not null
order by 3,4


-- Verify CovidVaccinations table has been populated after import from .xlsx file

select *
from [PortfolioProject]..CovidVaccinations
order by 3,4

-- Select Data that we are going to be using

select [location], [date], [total_cases], [new_cases], [total_deaths], [population]
from [PortfolioProject]..CovidDeaths
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths

select [location], [date], [total_cases], [total_deaths], 
DeathPercentage = (total_deaths/total_cases)*100 
from [PortfolioProject]..CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

select [location], [date], [population], [total_cases], 
InfectionPercentage = (total_cases/population)*100 
from [PortfolioProject]..CovidDeaths
where continent is not null
--where location like '%states%'
order by 1,2

--Look at countries with Highest Infection Rate compared to Population

select [location], [population],
HighestInfectionCount = max([total_cases]), 
InfectionPercentage = max((total_cases/population))*100 
from [PortfolioProject]..CovidDeaths
where continent is not null
--where location like '%states%'
group by [location], [population]
order by InfectionPercentage desc

-- Showing Countries with Highest Death Count per Population 

select [location], 
TotalDeathCount = max(cast(Total_deaths as int)) 
from [PortfolioProject]..CovidDeaths
where continent is not null
--where location like '%states%'
group by [location]
order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT

--Showing contintents with the highest death count per population

select [continent],
TotalDeathCount = max(cast(Total_deaths as int)) 
from [PortfolioProject]..CovidDeaths
where continent is not null
--where location like '%states%'
group by [continent]
order by TotalDeathCount desc


-- GLOBAL NUMBERS

select --[date], 
SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,  SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage  --,[total_deaths], 
from [PortfolioProject]..CovidDeaths
--where location like '%states%'
where continent is not null
--Group by date 
order by 1,2

-- Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date)/population)*100
from [PortfolioProject].[dbo].[CovidDeaths] dea
join [PortfolioProject].[dbo].[CovidVaccinations] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE

with PopvsVac --(Continent, Location, Date, Population, New_Vacinations, RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date)/population)*100
from [PortfolioProject].[dbo].[CovidDeaths] dea
join [PortfolioProject].[dbo].[CovidVaccinations] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac

-- TEMP TABLE

-- Check if temp table exists and remove it before rebuilding...this allows us to make modifications to the table and rebuild as needed

drop table if exists #PercentPopulationVaccinated

-- Create the #PercentPopulationVaccinated temp table, single # for local temp (## for global temp)

create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

-- Populate the temp table with our data

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date)/population)*100
from [PortfolioProject].[dbo].[CovidDeaths] dea
join [PortfolioProject].[dbo].[CovidVaccinations] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Veriy data has been inserted into temp table, begin looking at ratio of rolling ppl vaxed per population percentages

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentagePopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date)/population)*100
from [PortfolioProject].[dbo].[CovidDeaths] dea
join [PortfolioProject].[dbo].[CovidVaccinations] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

-- Verify PercentagePopulationVaccinated is functional and populated with data

select * 
from PercentagePopulationVaccinated


