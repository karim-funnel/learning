SELECT customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name AS full_name,
    email,
    active,
    store_id,
    create_date,
    last_update
FROM {{ source('public', 'customer') }}