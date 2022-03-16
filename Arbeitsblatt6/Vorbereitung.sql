--Batt 6

--1
select city.name,country.name from city
join country on country.code = city.country
where city.name = any (
select city.name from city
group by city.name having count(city.name) > 1);

--2
select count(country)  Anzahl from ismember
where organization like 'NATO';

--3
select count(name) anzahl from island
where islands like 'Lesser Antilles';


--4
select  distinct country.name countryname, geo_lake.lake lakename, lake.area from geo_lake 
join lake on lake.name = geo_lake.lake
join encompasses on encompasses.country = geo_lake.country
join country on country.code = geo_lake.country
where encompasses.continent like 'Europe';

--5

create view riverCount as
select river, count(distinct country) anzahllaender from geo_river 
group by river
order by anzahllaender desc;

select river, anzahllaender from riverCount
where anzahllaender = (select(max(anzahllaender)) from riverCount)
;

--6a
select country.name name, count(city.population) anzahl from city 
join country on country.code = city.country
where city.population  < 200000 and city.population > 100000
group by country.name
order by country.name;

--6b
drop view mediumCity;

create view mediumCity as
select country.name countryName ,city.name cityName from city 
join country on country.code = city.country
where city.population  < 200000 and city.population > 100000
;

select country.name, count(mediumCity.cityName) anzahl
from country
full outer join mediumCity on country.name = mediumCity.countryName
group by country.name
order by country.name asc;

--7
drop view nachbarn;
create view  nachbarn as
select country2 
from borders
where country1 like 'D'
union
select country1
from borders
where country2 like 'D';

select country.name 
from (
select country2 
from borders
where country1 like 'D'
union
select country1
from borders
where country2 like 'D')
join country on country.code = country2
;

--8
select distinct country.name from geo_river
join country on country.code = geo_river.country
where river like 'Donau'
;

--9
select sum(religion.percentage * country.population /100) anzahlprotestanten 
from religion
join country on country.code = religion.country
where religion.name like 'Protestant';

--10
select country.name, country.capital, city.population, encompasses.continent
from country
join encompasses on encompasses.country = country.code
join city on city.name = country.capital
where encompasses.continent like 'America' and city.country like country.code
order by country.name;

--11
select distinct country.name from country
join city on country.code = city.country
group by country.name,city.name having count(city.name) > 1;

--12
drop view religionAnhaenger;

create view religionAnhaenger as
select religion.name, sum(religion.percentage * country.population / 100) anzahl
from religion
join country on country.code = religion.country
group by religion.name
;

select name, anzahl 
from religionAnhaenger
where anzahl = (select min(anzahl) from religionAnhaenger);

--13
select geo_mountain.country, mountain.name, mountain.elevation
from mountain 
join geo_mountain on geo_mountain.mountain = mountain.name
where mountain.elevation like (
select max(mountain.elevation)
from mountain 
join geo_mountain on geo_mountain.mountain = mountain.name
join encompasses on encompasses.country = geo_mountain.country
where encompasses.continent like 'America');

--14
select river 
from geo_river 
group by river having count(distinct country) > 2
order by river;
--a)
select distinct a.river 
from geo_river a
where a.river = any(
    select river from geo_river b 
    where not b.country = a.country
    and b.river = any(
        select river 
        from geo_river c 
        where not b.country = c.country and not a.country = c.country))
order by river;


--b)
select distinct a.river 
from geo_river a
where exists(
    select river from geo_river b 
    where a.river like b.river
    and not b.country = a.country
    and b.river = any(
        select river 
        from geo_river c 
        where not b.country = c.country and not a.country = c.country))
order by river;

--15

select country.name, country.area / continent.area  * encompasses.percentage anteil
from country
join encompasses on encompasses.country = country.code 
join continent on encompasses.continent = continent.name
where continent.name like 'Europe';

--16
select country.name
from country
join city on city.country = country.code
group by country.name
having sum(city.population) is null
order by country.name;

select country.name
from country
join city on country.code = city.country
minus
select country.name
from country
join city on country.code = city.country
where city.population is not null;

--17
select religion.name, sum(country.population * religion.percentage ) / (select sum(country.population) from country) anteil
from religion
join country on country.code =religion.country
group by religion.name;

--18
select organization.name, sum(country.population) anzahleinwohner
from organization
join ismember on ismember.organization = organization.abbreviation
join country on country.code = ismember.country
group by organization.name
order by organization.name;

--19
select country.name, avg(city.population) durchschnitt
from city
join country on city.country = country.code
group by country.name
having count(city.name) > 100;

--20
select city.latitude from city where city.name like 'Berlin';
select city.name 
from city
where city.latitude between (select city.latitude from city where city.name like 'Berlin') -1 and (select city.latitude from city where city.name like 'Berlin') +1;

--Blatt 7

--1
select encompasses.continent, count(city.name)anzahl
from encompasses
join city on city.country = encompasses.country
group by encompasses.continent
order by encompasses.continent;
--2
select country.code, country.name 
from country
minus 
select distinct country.code, country.name
from country
join geo_sea on geo_sea.country = country.code
;
--3
drop view landInfo;

create view landInfo as
select country.name, encompasses.continent, country.capital, city.population
from country
join encompasses on encompasses.country = country.code
join city on country.capital = city.name;

--4
select continent, sum(population)
from landInfo
group by continent;

--Blatt 8

--1
select name 
from city
where latitude = 0;

--2
select country.name
from country
minus 
select distinct country.name
from country
join geo_mountain on geo_mountain.country = country.code;

--3
drop view spracheInfo;

create view spracheInfo as 
select country.name, country.code country , count(language.name)anzahlsprachen
from country
join language on language.country = country.code
group by country.name, country.code;

select name,country, anzahlsprachen
from spracheInfo
where anzahlsprachen = (select max(anzahlsprachen) from spracheInfo);

--4

select country.name
from country
join city on country.capital = city.name and city.country = country.code 
where city.population < 500000 and country.code = any(select city.country from city group by city.country having count(city.name) > 5);

select country.name
from country join city on country.capital = city.name and country.code = city.country
where city.population < 500000 and (select count(a.name) from city A where a.country = country.code) > 5;
