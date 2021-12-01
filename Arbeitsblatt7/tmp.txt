select encompasses.continent, count(city.name)Anzahl from (city 
join country on city.country = country.code)
join encompasses on city.country = encompasses.country
group by encompasses.continent
order by continent;

