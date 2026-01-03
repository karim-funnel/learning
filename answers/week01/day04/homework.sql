-- Warmup
with filtered_film_length as (
    select 
        f.film_id,
        f.title,
        f.length
    from film f
    where f.length > (
        select 
            avg(f.length) as global_avg 
        from film f
    )
)

select * from filtered_film_length;

-- Task 1
with comedy_film_inventory as (
    select 
        f.film_id,
        f.title,
        c.name as category,
        i.inventory_id as iid
    from film f
    join film_category fc
    on fc.film_id = f.film_id
    join category c
    on c.category_id = fc.category_id
    join inventory i
    on i.film_id = f.film_id
    where c.name = 'Comedy'
), rental_and_payment as (
    select
        r.inventory_id,
        r.customer_id,
        p.amount
    from rental r
    join payment p
    on r.rental_id = p.rental_id
    where r.inventory_id in (select iid from comedy_film_inventory)
)

select 
    customer_id,
    sum(amount) as total_amount
from rental_and_payment
group by customer_id
order by total_amount desc
limit 10;

-- Task 2
with loyal_customers as (
    select
        c.customer_id,
        c.first_name || ' ' || c.last_name as customer_full_name,
        count(r.rental_id) as number_of_rentals
    from customer c
    join rental r
    on r.customer_id = c.customer_id
    group by c.customer_id
    having count(r.rental_id) > 20
), paying_customers as (
    select 
        sum(p.amount) as total_payment,
        p.customer_id,
        row_number() over (order by sum(p.amount) desc) as row_num
    from payment p
    group by p.customer_id
    order by total_payment desc
), total_paying_customers as (
    select count(*) as max_count from paying_customers
), top_20_number as (
    select ceiling(0.2*max_count) as top20 from total_paying_customers
), filtered_paying_customers as (
    select * from paying_customers where row_num <= (select * from top_20_number)
)

select * from loyal_customers lc
join filtered_paying_customers fpc
on fpc.customer_id = lc.customer_id
order by total_payment desc;

-- Task 3
with customers_per_store as ( -- including stores with 0 customers
    select
        s.store_id,
        count(c.customer_id) as num_customers
    from store s
    left join customer c
    on s.store_id = c.store_id
    group by s.store_id
    order by s.store_id asc
), rentals_per_store as (
    select
        count(r.rental_id) as num_rentals,
        c.store_id
    from rental r
    join customer c
    on r.customer_id = c.customer_id
    group by c.store_id
    order by c.store_id asc
), payment_per_store as (
    select
        sum(p.amount) as total_revenue,
        c.store_id
    from payment p
    join customer c
    on p.customer_id = c.customer_id
    group by c.store_id
    order by c.store_id asc
), revenue_per_customer as (
    select
        pps.store_id,
        (pps.total_revenue/cps.num_customers) as rev_per_customer
    from payment_per_store pps
    join customers_per_store cps
    on cps.store_id = pps.store_id
), rentals_per_customer_per_store as (
    select
        rps.store_id,
        (rps.num_rentals/cps.num_customers) as rentals_per_customer
    from rentals_per_store rps
    join customers_per_store cps
    on cps.store_id = rps.store_id
)

select
    cps.store_id,
    cps.num_customers,
    rps.num_rentals,
    pps.total_revenue,
    rpc.rev_per_customer,
    rpcps.rentals_per_customer
from customers_per_store cps
join rentals_per_store rps
on rps.store_id = cps.store_id
join payment_per_store pps
on pps.store_id = cps.store_id
join revenue_per_customer rpc
on rpc.store_id = cps.store_id
join rentals_per_customer_per_store rpcps
on rpcps.store_id = cps.store_id;
