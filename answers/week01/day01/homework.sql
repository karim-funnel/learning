-- Task 1

select film_id, title, l.name as language_name 
from film f
join language l
on l.language_id=f.language_id
limit 20;

-- Task 2
select f.title, c.name, f.rental_rate, f.replacement_cost
from film f
join film_category fc
on f.film_id = fc.film_id -- is this "on" necessary if the columns are named the same? can be all the ons at the end?
join category c
on fc.category_id = c.category_id
where c.name = 'Action';

-- Task 3
select c.customer_id, c.first_name || ' ' || c.last_name as full_name, c.store_id, c.activebool
from customer c;

-- Task 4
select 
    r.rental_id, 
    r.rental_date, 
    c.first_name || ' ' || c.last_name as customer_full_name, 
    s.first_name || ' ' || s.last_name as staff_full_name,
    sum(p.amount) as total_amount
from rental r
join customer c
on c.customer_id = r.customer_id
join staff s
on s.staff_id = r.staff_id
join payment p
on p.rental_id = r.rental_id
group by 
    r.rental_id,
    c.customer_id,
    s.staff_id
limit 50;

-- Task 5
select * from
(
    select
        c.customer_id,
        c.store_id,
        c.first_name || ' ' || c.last_name as customer_full_name,
        sum(p.amount) as total_paid
    from customer c
    join payment p
    on p.customer_id = c.customer_id
    where c.store_id = 1
    group by c.customer_id, c.store_id
    order by total_paid desc
    limit 5
) Union (
    select
        c.customer_id,
        c.store_id,
        c.first_name || ' ' || c.last_name as customer_full_name,
        sum(p.amount) as total_paid
    from customer c
    join payment p
    on p.customer_id = c.customer_id
    where c.store_id = 2
    group by c.customer_id, c.store_id
    order by total_paid desc
    limit 5
)
order by total_paid desc
;