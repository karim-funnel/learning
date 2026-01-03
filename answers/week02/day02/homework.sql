-- Warmup
SELECT customer_id,
    payment_date,
    amount,
    SUM(amount) OVER (
        ORDER BY payment_date
    ) as running_total
FROM payment;
-- Task 1
-- For each store and date, compute:
-- total revenue for that day
-- running total revenue up to that day (per store).
-- Use SUM(amount) OVER (PARTITION BY store_id ORDER BY date_trunc('day', payment_date)).
with revenue_per_day_per_store as (
    SELECT c.store_id,
        p.payment_date::date,
        sum(p.amount) as total_revenue_this_day
    from payment p
        join customer c on p.customer_id = c.customer_id
    group by c.store_id,
        p.payment_date::date
    order by p.payment_date::date ASC,
        c.store_id
)
select rds.store_id,
    rds.payment_date,
    rds.total_revenue_this_day,
    sum(rds.total_revenue_this_day) over (
        PARTITION BY store_id
        ORDER BY rds.payment_date
    )
from revenue_per_day_per_store as rds;
-- Task 2
with revenue_per_day_per_store as (
    SELECT c.store_id,
        p.payment_date::date,
        sum(p.amount) as total_revenue_this_day
    from payment p
        join customer c on p.customer_id = c.customer_id
    group by c.store_id,
        p.payment_date::date
    order by p.payment_date::date ASC,
        c.store_id
)
select rds.store_id,
    rds.payment_date,
    rds.total_revenue_this_day,
    avg(rds.total_revenue_this_day) over (
        PARTITION BY store_id
        ORDER BY rds.payment_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )
from revenue_per_day_per_store as rds;
--Task 3
with revenue_per_day_per_customer as (
    SELECT c.customer_id,
        p.payment_date::date,
        sum(p.amount) as total_spent_this_day
    from payment p
        join customer c on p.customer_id = c.customer_id
    group by c.customer_id,
        p.payment_date::date
    order by c.customer_id,
        p.payment_date::date ASC
),
customer_spending as (
    select rdc.customer_id,
        rdc.payment_date,
        rdc.total_spent_this_day,
        sum(rdc.total_spent_this_day) over (
            PARTITION BY customer_id
            ORDER BY rdc.payment_date
        ) as sum_up_to_this_day
    from revenue_per_day_per_customer as rdc
),
date_100_dls as (
    select *,
        case
            WHEN sum_up_to_this_day >= 100 then payment_date
            else NULL
        end as date_crossed_100_dls
    from customer_spending
),
only_customer_and_date as (
    select customer_id,
        min(date_crossed_100_dls) as date_to_reach_100_dls
    from date_100_dls
    group by customer_id
)
select cs.*,
    ocd.date_to_reach_100_dls
from customer_spending cs
    join only_customer_and_date ocd on ocd.customer_id = cs.customer_id;