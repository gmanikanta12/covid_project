select * from [covid data].[dbo].['covid-death$']
order by 3,4

select * from [covid data].[dbo].['covid-vaccine$']
order by 3,4

-- select the data we are going to use 

select location,date,population,total_cases,new_cases,total_deaths
from [covid data].[dbo].['covid-death$']
order by 1,2

-- 1. find death percentage of total cases according to location

select location, date,total_cases,total_deaths,(total_deaths/total_cases)*100 as death_percentage
from [covid data].[dbo].['covid-death$']
where location like '%ndia%'
order by 5 

--2. find total cases vs population as infected percentage in india
select location,date,total_cases,population,(total_cases/population)*100 as infected_percentage
from [covid data].[dbo].['covid-death$']
 where location = 'India'
order by 5 desc


-- 3.find which country has highest infected rate 
select location,population,max(total_cases) highest_infected_count,max((total_cases/population))*100 as infected_percentage
from [covid data].[dbo].['covid-death$']
where continent is not null
group by location,population
order by 4 desc

--4 find country with highest death count
select location,population,max(cast(total_deaths as int)) as total_death_count,max((total_deaths/population))*100 as death_count_per_population
from [covid data].[dbo].['covid-death$']
where continent is not null
group by location,population
order by total_death_count desc

--5. find country with hihest death count per population
select location,population,max(cast(total_deaths as int)) as total_death_count,max((total_deaths/population))*100 as death_count_per_population
from [covid data].[dbo].['covid-death$']
where continent is not null
group by location,population
order by death_count_per_population desc

--6. find in which date highest new cases registered in india
select location,date,max(new_cases) as max_new_cases
from [covid data].[dbo].['covid-death$']
where continent is not null 
and location='India'
group by location,date
order by 3 desc

--7. in which date higest number of deaths occured in india
select location,date,max(cast(new_deaths as int)) as max_death_occured
from [covid data].[dbo].['covid-death$']
where continent is not null
and location='India'
group by location,date
order by 3 desc

--8.find in which date highest new cases registered in world
select location,date,max(new_cases) as max_new_cases
from [covid data].[dbo].['covid-death$']
where continent is not null
group by location,date
order by 3 desc

--9. in which date higest number of deaths occured in world
select location,date,max(cast(new_deaths as int)) as max_death_occured
from [covid data].[dbo].['covid-death$']
where continent is not null
group by location,date
order by 3 desc

-- join vaccination data to death data

select * 
from [covid data].[dbo].['covid-death$'] d
join [covid data].[dbo].['covid-vaccine$'] v
on d.location=v.location and d.date=v.date

-- looking for population vs vaccination

select d.location,d.date,d.population,v.new_vaccinations
, sum(convert(bigint,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as sum_of_vaccinations
from [covid data].[dbo].['covid-death$'] d
join [covid data].[dbo].['covid-vaccine$'] v
on d.location=v.location and d.date=v.date
--group by d.location,d.date,d.population
order by 1,2


-- here we have to use sum_of vaccinations column and get percentage from population to it.
-- thats why we need cte this time

--USING CTE

with populationvsvaccination (location,date,population,new_vaccinations,sum_of_vaccinations)
as (
select d.location,d.date,d.population,v.new_vaccinations
, sum(convert(bigint,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as sum_of_vaccinations
from [covid data].[dbo].['covid-death$'] d
join [covid data].[dbo].['covid-vaccine$'] v
on d.location=v.location and d.date=v.date
where d.continent is not null
)
select * ,((sum_of_vaccinations)/population)*100 as percentage_of_population_vaccinated
from populationvsvaccination


-- now to get maximum of the people vaccinated we remove date by creating temp table

-- TEMP TABLE
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
sum_of_vaccinations numeric
)
insert into #percentpopulationvaccinated

select d.location,d.date,d.population,v.new_vaccinations
, sum(convert(bigint,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as sum_of_vaccinations
from [covid data].[dbo].['covid-death$'] d
join [covid data].[dbo].['covid-vaccine$'] v
on d.location=v.location and d.date=v.date
where d.continent is not null

select * ,((sum_of_vaccinations)/population)*100 as percentage_of_population_vaccinated
from #percentpopulationvaccinated
where location='India'

-- lets create a view 
drop view if exists percentpopulationvaccinated
go
create view percentpopulationvaccinated as

select d.location,d.date,d.population,v.new_vaccinations
, sum(convert(bigint,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as sum_of_vaccinations
from [covid data].[dbo].['covid-death$'] d
join [covid data].[dbo].['covid-vaccine$'] v
on d.location=v.location and d.date=v.date
where d.continent is not null
