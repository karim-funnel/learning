{{
  config(
    materialized='incremental',
    unique_key='rental_id'
  )
}}

SELECT
    r.rental_id,
    r.rental_date,
    r.customer_id,
    r.inventory_id,
    r.staff_id,
    p.amount AS payment_amount,
    r.return_date,
    CASE
        WHEN r.return_date IS NULL THEN TRUE
        ELSE FALSE
    END AS is_outstanding
FROM {{ ref('stg_rentals') }} r
LEFT JOIN {{ ref('stg_payments') }} p USING (rental_id)

{% if is_incremental() %}
    WHERE r.rental_date > (SELECT MAX(rental_date) FROM {{ this }})
{% endif %}