select * 
from PortfolioProject..CovidDeaths
order by 3,4

--select * 
--from PortfolioProject..CovidVaccinations
--order by 3,4

-- select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at Total Cases vs Populations
-- Shows what percentage of population got covid

select location, date, population, total_cases, (total_cases/population)*100 as CaseRate
from CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at countries with Highest Infection Rate compared to Population

select location, population, Max(total_cases) as TotalCases, Max((total_cases/population))*100 as CaseRate
from CovidDeaths
group by location, population
order by CaseRate desc

-- Showing countries with Highest Death Count compared to population
select location, max(cast(total_deaths as int)) as TotalDeaths
from CovidDeaths
where continent is not null
group by location
order by TotalDeaths desc

-- LET'S BREAK THINGS DOWN BY CONTINENT
select continent, max(cast(total_deaths as int)) as TotalDeaths
from CovidDeaths
where continent is not null
group by continent
order by TotalDeaths desc

-- GLOBAL NUMBERS

select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathRate
from CovidDeaths
where continent is not null
group by date
order by 1

select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathRate
from CovidDeaths
where continent is not null
--group by date
order by 1,2


-- Looking total Population vs Vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as TotalVacination
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE

with PopVsVac as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingTotalVacination
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

select continent,location,date,population, RollingTotalVacination, (RollingTotalVacination/population)*100 as VacinationRate
from PopVsVac


-- Max vaccination rate for the location
--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
create table #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinate numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingTotalVacination
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select Location, max(VacinationRate) as VaccinatedPercent from (Select *, (RollingPeopleVaccinate/Population)*100 as VacinationRate
from #PercentPopulationVaccinated) t group by Location order by VaccinatedPercent desc

-- Creating View to store data for later visualisation

create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as RollingTotalVaccination
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select * 
from PercentPopulationVaccinated
