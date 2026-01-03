-- Warmup
select
    f.rating,
    count(f.rating) as number_of_films
from film f
group by f.rating;

select
    f.rating,
    avg(f.rental_rate) as avg_rental_rate,
    avg(f.replacement_cost) as avg_replacement_cost
from film f
group by f.rating;

-- Task 1
select
    s.store_id,
    sum(c.activebool::int) as active_customers,
    count(*) - sum(c.activebool::int) as inactive_customers
from store s
join customer c 
on c.store_id = s.store_id
group by s.store_id;

-- Task 2
select
    c.name,
    sum(p.amount) as total_revenue,
    count(r.rental_id) as number_of_rentals
from category c
left join film_category fc
on fc.category_id = c.category_id
left join inventory i
on i.film_id = fc.film_id
left join rental r
on r.inventory_id = i.inventory_id
left join payment p
on r.rental_id = p.rental_id
group by c.name
order by total_revenue desc
limit 5;

-- Task 3
select
    s.staff_id,
    count(r.rental_id) as rentals_processed,
    sum(p.amount) as payments_collected,
    avg(p.amount) as avg_payment_collected
from staff s
left join rental r
on r.staff_id = s.staff_id
left join payment p 
on p.rental_id = r.rental_id
group by s.staff_id
having count(r.rental_id) > 0 -- probably inner join is faster?
order by payments_collected desc;

-- Task 4
select
    p.customer_id,
    avg(p.amount) as customer_avg
from payment p
group by customer_id
having avg(p.amount) > (select
    avg(p.amount) as global_avg
from payment p);