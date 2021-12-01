-- Aufgabe 1 a TODO
create view doubles as
select name
from city
group by name
having count(*) > 1;

select city.name Stadt, country.name Land
from country inner join city on city.country = country.code
where exists (select name from doubles where doubles.name = country.name);

-- Aufgabe 1 a (alternativ) TODO (91%)
select city.name STADT, country.name LAND
from city join country on city.country = country.code
where exists (select a.name from city a where a.name = city.name and not city.country = a.country);

-- Aufgabe 2 b
select count(country) Anzahl
from ismember
where organization like 'NATO';

-- Aufgabe 3 c
select count(*) Anzahl
from island
where islands like 'Lesser Antilles';

-- Aufgabe 4 d
select distinct country.name COUNTRYNAME, lake.name LAKENAME, lake.area AREA
from geo_lake join country on country.code = geo_lake.country join lake on geo_lake.lake = lake.name join encompasses on country.code = encompasses.country
where continent like 'Europe';

-- Aufgabe 5 e
create view anzahlen as
select river, count(distinct country) ANZAHL
from geo_river
group by river;

select river, anzahl 
from anzahlen
where anzahl = (select max(anzahl) from anzahlen);

-- Aufgabe 6 f TODO
select country.name, count(city) ANZAHL
from country left outer join city on country.code = city.country join citypops on city.name = citypops.city
where year = (select max(year) from countrypops where city.country = countrypops.country and citypops.population between 100000 and 200000)
group by country.name
order by country.name;

-- Aufgabe 7 g
select country.name
from borders join country on country.code = borders.country1
where country2 like 'D'
union
select country.name
from borders join country on country.code = borders.country2
where country1 like 'D';

-- Aufgabe 8 h
select country.name
from geo_river join country on country.code = geo_river.country
where river = 'Donau'
group by country.name
order by country.name;

-- Aufgabe 9 i
select sum(percentage*population/100) ANZAHLPROTESTANTEN
from religion join countrypops on religion.country = countrypops.country
where name like 'Protestant' and year = (select max(year) from countrypops where religion.country = countrypops.country);

-- Aufgabe 10 j TODO (86%)
select country.name, country.capital, city.population, encompasses.continent
from country join encompasses on country.code = encompasses.country left join city on country.capital = city.name
where encompasses.continent = 'America'
order by country.name;

-- Aufgabe 10 j (alternativ) TODO (95%)
select country.name, country.capital, citypops.population, encompasses.continent
from country join encompasses on country.code = encompasses.country left join citypops on country.capital = citypops.city  and year = (select max(year) from citypops where country.capital = citypops.city)
where encompasses.continent = 'America'
order by country.name;

-- Aufgabe 11 k TODO
select country.name, city.name
from city left outer join country on country.code = city.country
minus
select country.name, city.name
from city join country on country.code = city.country

-- Aufgabe 12 l TODO
select religion.name, percentage*population ANZAHL
from religion join countrypops on religion.country = countrypops.country
where year = (select max(year) from countrypops where religion.country = countrypops.country) and percentage*population = (select min(percentage*population) from religion join countrypops on religion.country = countrypops.country);

-- Aufgabe 13 m
select encompasses.country, mountain.name, mountain.elevation
from mountain join geo_mountain on geo_mountain.mountain = mountain.name join encompasses on geo_mountain.country = encompasses.country
where encompasses.continent like 'America' and elevation = (select max(elevation) from mountain join geo_mountain on geo_mountain.mountain = mountain.name join encompasses on geo_mountain.country = encompasses.country where encompasses.continent like 'America');

-- Aufgabe 14 n a  TODO

-- Aufgabe 14 n b TODO
select distinct river
from geo_river a
where exists (select river from geo_river b where (not (a.country = b.country)) and a.river = b.river)
order by a.river;

-- Aufgabe 15 o
select country.name, country.area / continent.area * 100 ANTEIL
from country join encompasses on country.code = encompasses.country join continent on continent.name = encompasses.continent
where continent.name like 'Europe';

-- Aufgabe 16 p
select country.name
from country
where not exists (Select city.population from city where country.code = city.country and city.population is not null);

-- Aufgabe 16 p (alternativ)
select country.name
from country join city on country.code = city.country
group by country.name
having count(city.population) = 0;

-- Aufgabe 17 q
select religion.name, sum(religion.percentage*country.population)/(select sum(population) from country) ANTEIL
from religion join country on religion.country = country.code
group by religion.name;

-- Aufgabe 18 r
select organization.name, sum(country.population) ANZAHLEINWOHNER
from organization join ismember on organization.abbreviation = ismember.organization join country on country.code = ismember.country
group by organization.name;

-- Aufgabe 19 s (nicht im SQLTrainer)
select country.name, avg(city.population) DURCHSCHNITT
from country join city on country.code = city.country
group by country.name
having count(city.name) > 100;

-- Aufgabe 20 t (nicht im SQLTrainer)
select city.name
from city
where latitude <= (select latitude from city where name like 'Berlin') + 1 and latitude >= (select latitude from city where name like 'Berlin') -1
order by city.name;
