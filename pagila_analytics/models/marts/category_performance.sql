WITH film_categories AS (
    SELECT
        f.film_id,
        f.title,
        c.name AS category_name,
        f.rental_rate,
        f.replacement_cost
    FROM {{ source('public', 'film') }} f
    INNER JOIN {{ source('public', 'film_category') }} fc USING (film_id)
    INNER JOIN {{ source('public', 'category') }} c USING (category_id)
),

rental_revenue AS (
    SELECT
        r.inventory_id,
        SUM(p.amount) AS total_revenue,
        COUNT(DISTINCT r.rental_id) AS rental_count
    FROM {{ ref('stg_rentals') }} r
    INNER JOIN {{ ref('stg_payments') }} p USING (rental_id)
    GROUP BY r.inventory_id
),

inventory_films AS (
    SELECT
        inventory_id,
        film_id
    FROM {{ source('public', 'inventory') }}
)

SELECT
    fc.category_name,
    COUNT(DISTINCT fc.film_id) AS films_in_category,
    SUM(rr.rental_count) AS total_rentals,
    SUM(rr.total_revenue) AS total_revenue,
    AVG(rr.total_revenue) AS avg_revenue_per_film,
    SUM(rr.total_revenue) / NULLIF(SUM(rr.rental_count), 0) AS revenue_per_rental
FROM film_categories fc
LEFT JOIN inventory_films if USING (film_id)
LEFT JOIN rental_revenue rr USING (inventory_id)
GROUP BY fc.category_name
ORDER BY total_revenue DESC