-- Task 1
with active_customers_summary as (
    select distinct customer_id,
        date_trunc('month', rental_date)::date as month
    from rental
),
reactivated as (
    select count(*) as reactivated_customers,
        a.month
    from active_customers_summary a
        left join active_customers_summary p on p.month = a.month - interval '1 month'
        and p.customer_id = a.customer_id
    where p.customer_id is NULL
    group by a.month
),
churned as (
    select count(*) as churned_customers,
        (p.month + interval '1 month')::date as month
    from active_customers_summary p
        left join active_customers_summary a on a.customer_id = p.customer_id
        and a.month = (p.month + interval '1 month')::date
    where a.customer_id is null
    group by (p.month + interval '1 month')::date
)
select r.reactivated_customers,
    coalesce(r.month, c.month) as month,
    c.churned_customers
from reactivated r
    full join churned c on r.month = c.month
order by month asc;
--
-- Task 2 -- pending!
with payment_per_store_per_month as (
    select sum(p.amount) as total_revenue,
        c.store_id,
        date_trunc('month', r.rental_date)::date as month
    from payment p
        join customer c on p.customer_id = c.customer_id
        join rental r on r.rental_id = p.rental_id
    group by c.store_id,
        date_trunc('month', r.rental_date)::date
)
select r.staff_id,
    count(r.staff_id),
    sum(p.amount),
    c.store_id,
    date_trunc('month', r.rental_date)::date as month
from rental r
    join payment p on p.rental_id = r.rental_id
    join customer c on r.customer_id = c.customer_id
group by r.staff_id,
    c.store_id,
    date_trunc('month', r.rental_date)::date;