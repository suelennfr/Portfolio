SELECT *
FROM Portifolio..coviddeaths
ORDER BY location, date;

SELECT *
FROM Portifolio..covidvaccination
ORDER BY location, date;

-- Selecionando os dados que serão usados
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portifolio..coviddeaths
ORDER BY location, date;

-- Verificando total de casos x Total de mortes no Brasil
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate --% de mortes por casos confirmados
FROM Portifolio..coviddeaths
WHERE location = 'Brazil'
ORDER BY location, date;

-- Verificando total de casos x população no Brasil
SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionRate
FROM Portifolio..coviddeaths
WHERE location = 'Brazil'
ORDER BY location, date;

-- Verificando os paises com maiores índices de infecção em relação à população
SELECT location, population, MAX(total_cases) AS HighestCasesCount, MAX((total_cases/population)*100) AS InfectionRate
FROM Portifolio..coviddeaths
GROUP BY location, population
ORDER BY InfectionRate DESC;

-- Verificando paises com maiores numeros de mortes por população
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Portifolio..coviddeaths
GROUP BY location
ORDER BY TotalDeathCount DESC;
--foi necessário alterar o tipo da coluna total_deaths pois na primeira consulta percebemos 
--que o total de mortes estava todo começado em 99, então verificando o tipo dos dados percebemos 
--que era varchar, por isso deu um resultado estranho.

--aqui também verificamos que há algumas localidades como World ou Asia, que incluem mais de um país.
--isso acontece quando o continente está em branco, entao a location fica sendo o continente
--então em todas queries adicionamos WHERE continent is not null ** e na verdade essa conclusao estava errada

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
--aqui vemos os numeros reais. a coluna location tem os numeros corretos e a continent nao é muito precisa
--dados checados no google

--Números globais
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

-- Verificando total da população x vacinação
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
	--,(PeopleVaccinated/population)*100   >>> nao podemos usar um alias criado para um calculo (PeopleVaccinated) na mesma linha de código
FROM Portifolio..coviddeaths AS dea
INNER JOIN Portifolio..covidvaccination as vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY continent, location, date

-- como nao podemos usar um alias criado para um calculo (PeopleVaccinated) na mesma linha de código,
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

--Criando uma tabela temporária (TEMP TABLE)
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
	--,(PeopleVaccinated/population)*100   >>> nao podemos usar um alias criado para um calculo (PeopleVaccinated) na mesma linha de código
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