-- This test will fail if there are any negative payment amounts
SELECT
    payment_id,
    amount
FROM {{ ref('stg_payments') }}
WHERE amount < 0