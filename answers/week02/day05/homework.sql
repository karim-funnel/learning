-- Overall revenue trend (daily or weekly) over time
select sum(p.amount) as total_revenue,
    date_trunc('day', r.rental_date)::date as day
from payment p
    join rental r on r.rental_id = p.rental_id
group by date_trunc('day', r.rental_date)::date
order by day asc;
-- Top 10 customers and their key stats (total spend, total rentals, preferred categories).
with category_frequency as (
    SELECT c.customer_id,
        cat.name,
        count(cat.name) as category_count
    FROM customer c
        JOIN rental r ON r.customer_id = c.customer_id
        JOIN inventory i on r.inventory_id = i.inventory_id
        join film_category fc on fc.film_id = i.film_id
        join category cat on cat.category_id = fc.category_id
    group by c.customer_id,
        cat.name
),
customer_with_fav_category as (
    select *,
        row_number() over (
            PARTITION by cf.customer_id
            order by cf.category_count desc
        ) as favorite_rank
    from category_frequency cf
)
SELECT c.customer_id,
    COUNT(r.rental_id) as total_rentals,
    SUM(p.amount) as total_spend,
    cf.name
FROM customer c
    JOIN rental r ON r.customer_id = c.customer_id
    JOIN payment p ON p.rental_id = r.rental_id
    join customer_with_fav_category cf on cf.customer_id = c.customer_id
where cf.favorite_rank = 1
GROUP BY c.customer_id,
    cf.name
ORDER BY total_spend DESC
limit 10;
-- Category performance (revenue, growth vs previous period).