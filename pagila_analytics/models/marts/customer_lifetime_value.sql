WITH customer_payments AS (
    SELECT customer_id,
        COUNT(DISTINCT rental_id) AS total_rentals,
        SUM(amount) AS total_paid,
        AVG(amount) AS avg_payment,
        MIN(payment_date) AS first_payment_date,
        MAX(payment_date) AS last_payment_date
    FROM {{ ref('stg_payments') }}
    GROUP BY customer_id
),
customer_info AS (
    SELECT customer_id,
        full_name,
        email,
        store_id,
        active
    FROM {{ ref('stg_customers') }}
)
SELECT c.customer_id,
    c.full_name,
    c.email,
    c.store_id,
    c.active,
    COALESCE(p.total_rentals, 0) AS total_rentals,
    COALESCE(p.total_paid, 0) AS total_paid,
    COALESCE(p.avg_payment, 0) AS avg_payment,
    p.first_payment_date,
    p.last_payment_date,
    CASE
        WHEN p.total_paid > 150 THEN 'high'
        WHEN p.total_paid > 50 THEN 'medium'
        ELSE 'low'
    END AS customer_segment,
    {{ cents_to_dollars('p.total_paid') }} AS total_paid,
    {{ cents_to_dollars('p.avg_payment') }} AS avg_payment
FROM customer_info c
    LEFT JOIN customer_payments p USING (customer_id)