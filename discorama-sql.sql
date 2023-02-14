*/ 
PROJETO ANALISTA DE DADOS
CLIENTE FICTÍCIO: DISCORAMA
PROGRAMA LIGHTHOUSE - INDICIUM
*\

-- Verificando a relação entre o dataset de aluguel com o de pagamento

SELECT rental.rental_id, rental.customer_id, rental.rental_date, rental.return_date, payment.amount, payment.payment_date
FROM Discorama.dbo.rental AS rental
INNER JOIN Discorama.dbo.payment AS payment
ON rental.rental_id = payment.rental_id;

-- Integrando datasets para analisar dados de pagamento e aluguel por país

SELECT DISTINCT rental.rental_id, rental.rental_date, customer.customer_id, address.city_id, city.country_id, country.country, payment.amount
FROM Discorama.dbo.customer AS customer
INNER JOIN Discorama.dbo.address AS address
ON customer.address_id = address.address_id
	INNER JOIN Discorama.dbo.city AS city
	ON address.city_id = city.city_id
		INNER JOIN Discorama.dbo.country AS country
		ON city.country_id = country.country_id
			INNER JOIN Discorama.dbo.rental AS rental
			ON customer.customer_id = rental.customer_id
				INNER JOIN Discorama.dbo.payment AS payment
				ON rental.rental_id = payment.rental_id
WHERE rental.rental_date <> '2006-02-14'
	AND payment.amount <> '0.00'

