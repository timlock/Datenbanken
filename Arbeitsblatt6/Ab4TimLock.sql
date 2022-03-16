--a)
select city.name,country.name from city
join country on country.code = city.country
where city.name = any (
select city.name from city
group by city.name having count(city.name) > 1);

--b)

select count(country) anzahl from ismember
where organization like 'NATO';

--c)

select count(name) anzahl from island
where islands like 'Lesser Antilles';

--d)

