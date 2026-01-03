-- Warmup
select
    f.title as film_title,
    c.name as category_name
from film f
join film_category fc
on fc.film_id = f.film_id
join category c
on fc.category_id = c.category_id;

select
    f.title as film_title,
    c.name as category_name
from film f
left join film_category fc
on fc.film_id = f.film_id
left join category c
on fc.category_id = c.category_id;

-- Task 1
select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_full_name,
    c.email,
    c.store_id
from customer c
left join rental r
on r.customer_id = c.customer_id
where r.customer_id is NULL;

-- Task 2
select
    f.title as film_title
from film f
left join inventory i
on i.film_id = f.film_id
left join rental r
on r.inventory_id = i.inventory_id
group by f.film_id
having count(r.rental_id) = 0;


-- Task 3
select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_full_name,
    count(r.customer_id) as number_of_rentals,
    max(r.rental_date) as most_recent_rental
from customer c
left join rental r
on r.customer_id = c.customer_id
group by c.customer_id
order by number_of_rentals desc;

-- Task 4
select
    sta.first_name || ' ' || sta.last_name as staff_full_name,
    sto.store_id as store_assigned
from staff sta
full join store sto
on sta.store_id = sto.store_id
order by sto.store_id;