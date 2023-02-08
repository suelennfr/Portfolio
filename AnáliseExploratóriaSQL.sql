/* 
Análise exploratória de dados referentes ao Covid 19 utilizando o SQL (SSMS)
Fonte: https://ourworldindata.org/covid-deaths
Projeto guiado por: https://github.com/AlexTheAnalyst

Dados verificados no Excel e importados no SQL Server Management Studio
*/

-- Verificando os dados importados

SELECT *
FROM Portifolio..coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

SELECT *
FROM Portifolio..covidvaccination
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Verificou-se que algumas localidades estão descritas como World, nomes de continentes ou descrições de renda.
-- Como as mesmas não possuem informações de continente, as consultas serão feitas desconsiderando as linhas sem informação de continente.

-- Selecionando os dados que serão utilizados

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portifolio..coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Verificando a probabilidade de morte em caso de contaminação no Brasil

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate --% de mortes por casos confirmados
FROM Portifolio..coviddeaths
WHERE location = 'Brazil' AND continent IS NOT NULL
ORDER BY location, date;

-- Porcentagem de casos no Brasil em relação à população

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionRate
FROM Portifolio..coviddeaths
WHERE location = 'Brazil'
ORDER BY location, date;

-- Analisando os países com maior número de contaminação

SELECT location, population, MAX(total_cases) AS HighestCasesCount, MAX((total_cases/population)*100) AS InfectionRate
FROM Portifolio..coviddeaths
GROUP BY location, population
ORDER BY InfectionRate DESC;

-- Analisando os países com maior número de mortes em relação à população
-- (foi necessário alterar o tipo da coluna total_deaths pois a primeira consulta retornou valores imprecisos devido ao tipo da coluna ser varchar)

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Portifolio..coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Número de mortes por continente (dados checados no Google)

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Portifolio..coviddeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Totais globais de casos, mortes e a taxa de mortes por casos

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as DeathRate
FROM Portifolio..coviddeaths
WHERE continent is not null
GROUP BY date
ORDER BY date, total_cases;


-- Informações sobre vacinação

SELECT *
FROM Portifolio..coviddeaths AS dea
INNER JOIN Portifolio..covidvaccination as vac
ON dea.location = vac.location
	AND dea.date = vac.date

-- Porcentagem da população que recebeu pelo menos uma dose da vacina

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
	--,(PeopleVaccinated/population)*100   
FROM Portifolio..coviddeaths AS dea
INNER JOIN Portifolio..covidvaccination as vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY continent, location, date

-- Incluindo CTE

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

--Criando uma tabela temporária para armazenar informações que podem ser utilizadas posteriormente

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

