-- Warmup
select f.title,
    c.name,
    f.rental_rate,
    row_number() over (
        partition by fc.category_id
        order by f.rental_rate desc
    ) as row_number
from film f
    join film_category fc on f.film_id = fc.film_id
    join category c on c.category_id = fc.category_id
order by f.title asc;
-- Warmup 2
with sorted_films as (
    select f.title,
        c.name,
        f.rental_rate,
        row_number() over (
            partition by fc.category_id
            order by f.rental_rate desc
        ) as row_number
    from film f
        join film_category fc on f.film_id = fc.film_id
        join category c on c.category_id = fc.category_id
    order by f.title asc
)
select *
from sorted_films
where row_number <= 3;
-- Task 1
with ranked_customers as (
    select c.customer_id,
        c.store_id,
        c.first_name || ' ' || c.last_name as customer_full_name,
        sum(p.amount) as total_paid,
        rank() over (
            PARTITION BY store_id
            ORDER BY sum(p.amount) DESC
        ) as rank1,
        dense_rank() over (
            PARTITION BY store_id
            ORDER BY sum(p.amount) DESC
        ) as rank2
    from customer c
        join payment p on p.customer_id = c.customer_id
    group by c.customer_id,
        c.store_id
)
select customer_id,
    store_id,
    customer_full_name,
    rank1 as normal_rank
from ranked_customers
where rank1 <= 3;
-- use this if you want normal rank
select customer_id,
    store_id,
    customer_full_name,
    rank2 as dense_rank
from ranked_customers
where rank2 <= 3;
-- use this if you want dense rank
-- Task 2
with profitable_films as (
    select f.title,
        c.name,
        sum(p.amount) as total_revenue,
        sum(p.amount) / f.replacement_cost as profitability_index,
        rank() over (
            partition by fc.category_id
            order by sum(p.amount) / f.replacement_cost desc
        ) as rank
    from film f
        join film_category fc on fc.film_id = f.film_id
        join category c on c.category_id = fc.category_id
        join inventory i on i.film_id = f.film_id
        join rental r on r.inventory_id = i.inventory_id
        join payment p on p.rental_id = r.rental_id
    group by f.film_id,
        c.category_id,
        fc.category_id
)
select *
from profitable_films
where rank <= 5;
-- Task 3
with ranked_customers as (
    select c.customer_id,
        c.store_id,
        c.first_name || ' ' || c.last_name as customer_full_name,
        sum(p.amount) as total_paid,
        rank() over (
            PARTITION BY store_id
            ORDER BY sum(p.amount) DESC
        ) as rank1,
        dense_rank() over (
            PARTITION BY store_id
            ORDER BY sum(p.amount) DESC
        ) as rank2,
        count(*) over (partition by store_id) as count
    from customer c
        join payment p on p.customer_id = c.customer_id
    group by c.customer_id,
        c.store_id
)
select store_id,
    customer_full_name,
    total_paid,
    count,
    rank1 as normal_rank,
    case
        WHEN (rank1::float / count::float) > 0.1 then 'No'
        else 'Yes'
    end as is_percentile_10
from ranked_customers;