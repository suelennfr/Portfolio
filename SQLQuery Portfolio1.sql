SELECT *
FROM Portifolio..coviddeaths
ORDER BY location, date;

SELECT *
FROM Portifolio..covidvaccination
ORDER BY location, date;

-- Selecionando os dados que ser�o usados
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portifolio..coviddeaths
ORDER BY location, date;

-- Verificando total de casos x Total de mortes no Brasil
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate --% de mortes por casos confirmados
FROM Portifolio..coviddeaths
WHERE location = 'Brazil'
ORDER BY location, date;

-- Verificando total de casos x popula��o no Brasil
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionRate
FROM Portifolio..coviddeaths
WHERE location = 'Brazil'
ORDER BY location, date;

-- Verificando os paises com maiores �ndices de infec��o em rela��o � popula��o
SELECT location, population, MAX(total_cases) AS HighestCasesCount, MAX((total_cases/population)*100) AS InfectionRate
FROM Portifolio..coviddeaths
GROUP BY location, population
ORDER BY InfectionRate DESC;

-- Verificando paises com maiores numeros de mortes por popula��o
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Portifolio..coviddeaths
GROUP BY location
ORDER BY TotalDeathCount DESC;
--foi necess�rio alterar o tipo da coluna total_deaths pois na primeira consulta percebemos 
--que o total de mortes estava todo come�ado em 99, ent�o verificando o tipo dos dados percebemos 
--que era varchar, por isso deu um resultado estranho.

--aqui tamb�m verificamos que h� algumas localidades como World ou Asia, que incluem mais de um pa�s.
--isso acontece quando o continente est� em branco, entao a location fica sendo o continente
--ent�o em todas queries adicionamos WHERE continent is not null ** e na verdade essa conclusao estava errada

--VERIFICANDO POR CONTINENTE
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Portifolio..coviddeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC;
--aqui percebemos que a america do norte inclui somente os dados dos estados unidos

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Portifolio..coviddeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC;
--aqui vemos os numeros reais. a coluna location tem os numeros corretos e a continent nao � muito precisa
--dados checados no google

--N�meros globais
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathRate
FROM Portifolio..coviddeaths
WHERE continent is not null
GROUP BY date
ORDER BY date, total_cases;

--Totais mundiais
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathRate
FROM Portifolio..coviddeaths
WHERE continent is not null
ORDER BY total_cases;

--Juntando as duas tabelas
SELECT *
FROM Portifolio..coviddeaths AS dea
INNER JOIN Portifolio..covidvaccination as vac
ON dea.location = vac.location
	AND dea.date = vac.date
	--conferir se foram agrupadas corretamente

-- Verificando total da popula��o x vacina��o
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
	--,(PeopleVaccinated/population)*100   >>> nao podemos usar um alias criado para um calculo (PeopleVaccinated) na mesma linha de c�digo
FROM Portifolio..coviddeaths AS dea
INNER JOIN Portifolio..covidvaccination as vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY continent, location, date

-- como nao podemos usar um alias criado para um calculo (PeopleVaccinated) na mesma linha de c�digo,
--vamos criar uma CTE
WITH PopxVac AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM Portifolio..coviddeaths AS dea
INNER JOIN Portifolio..covidvaccination as vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (PeopleVaccinated/population)*100 AS PercentageVaccinations
FROM PopxVac

--Criando uma tabela tempor�ria (TEMP TABLE)
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
peoplevaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
	--,(PeopleVaccinated/population)*100   >>> nao podemos usar um alias criado para um calculo (PeopleVaccinated) na mesma linha de c�digo
FROM Portifolio..coviddeaths AS dea
INNER JOIN Portifolio..covidvaccination as vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (PeopleVaccinated/population)*100 AS PercentageVaccinations
FROM #PercentPopulationVaccinated



--Queries usadas no tableau

--1
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathRate
FROM Portifolio..coviddeaths
WHERE continent is not null
ORDER BY total_cases;

--2
SELECT location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM Portifolio..coviddeaths
WHERE continent is null
	AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC;

--3
SELECT location, population, MAX(total_cases) AS HighestCasesCount, MAX((total_cases/population)*100) AS InfectionRate
FROM Portifolio..coviddeaths
GROUP BY location, population
ORDER BY InfectionRate DESC;

--4
SELECT location, population, date, MAX(total_cases) AS HighestCasesCount, MAX((total_cases/population)*100) AS InfectionRate
FROM Portifolio..coviddeaths
GROUP BY location, population, date
ORDER BY InfectionRate DESC;