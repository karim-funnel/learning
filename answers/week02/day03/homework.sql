-- Warmup
with film_length_bucket as (
    select f.title,
        case
            WHEN f.length < 60 THEN '< 60 min'
            WHEN f.length BETWEEN 60 and 90 then '60-90 min'
            WHEN f.length BETWEEN 90 and 120 then '90-120 min'
            ELSE '> 120 min'
        END as length_bucket
    from film f
)
select flb.*,
    count(*) over (PARTITION by flb.length_bucket) as films_in_this_bucket
from film_length_bucket as flb;
--
-- Task 1
with spending_per_customer as (
    SELECT c.customer_id,
        c.store_id,
        sum(p.amount) as total_spent,
        case
            WHEN sum(p.amount) < 50 THEN 'low'
            WHEN sum(p.amount) BETWEEN 50 and 150 then 'medium'
            ELSE 'high'
        END as pay_bucket
    from payment p
        join customer c on p.customer_id = c.customer_id
    group by c.customer_id
)
select sc.store_id,
    sc.pay_bucket,
    sum(sc.total_spent),
    count(sc.store_id) as num_of_customers_in_store_and_bracket
from spending_per_customer as sc
GROUP BY sc.store_id,
    sc.pay_bucket;
--
-- Task 2
with rental_date_bucket as (
    select r.rental_id,
        p.amount,
        case
            WHEN extract(
                hour
                from r.rental_date
            ) BETWEEN 6 and 12 THEN 'Morning'
            WHEN extract(
                hour
                from r.rental_date
            ) BETWEEN 12 and 18 THEN 'Afternoon'
            WHEN extract(
                hour
                from r.rental_date
            ) BETWEEN 18 and 24 THEN 'Evening'
            ELSE 'Night'
        END as rental_time_of_day
    from rental r
        join payment p on p.rental_id = r.rental_id
)
select rental_time_of_day,
    count(*) as num_of_rentals,
    sum(rdb.amount) as revenue
from rental_date_bucket as rdb
group by rdb.rental_time_of_day;
--
-- Task 3
with rental_category_per_store as (
    select c.name as category_name,
        r.rental_id,
        i.store_id
    from category c
        left join film_category fc on fc.category_id = c.category_id
        left join inventory i on i.film_id = fc.film_id
        left join rental r on r.inventory_id = i.inventory_id
)
select rs.category_name,
    rs.store_id,
    count(rs.rental_id) as total_rentals,
    100 * count(rs.rental_id) / sum(count(rs.rental_id)) over (PARTITION by rs.store_id) as percentage_of_total
from rental_category_per_store rs
where rs.store_id >= 1
group by rs.category_name,
    rs.store_id
order by store_id asc;