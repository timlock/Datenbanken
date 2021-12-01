--1)
create view doppelt as select name, country from city 
where name = any(SELECT name FROM city
GROUP BY name HAVING COUNT(*) > 1);


select doppelt.name Stadt, e.name Land from doppelt join country e on doppelt.country = e.code
order by doppelt.name asc;

--6) a
select country.name Land,e.zahl from (
    select count(city.name)zahl, city.country from city 
    where population between 100000 and  200000
    group by city.country) e 
join country on country.code = e.country
order by e.country asc;  

--6) b
select country.name Land,e.zahl Anzahl from (
    select count(CASE WHEN population between 100000 and  200000 THEN city.name ELSE NULL END)zahl, city.country from city 
    group by city.country) e
right join country on country.code = e.country
order by e.country asc;  

--10)
select country.name, country.capital, country.population, e.continent 
from (select country,continent from encompasses where continent like 'America') e
join country on country.code = e.country
order by country.name;