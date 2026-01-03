# Pagila Database Schema Reference

Quick reference for all table structures. No more `\d table_name` needed!

---

## Table of Contents

**Core Business Tables:**

- [actor](#actor)
- [film](#film)
- [category](#category)
- [language](#language)
- [customer](#customer)
- [rental](#rental)
- [payment](#payment)
- [inventory](#inventory)
- [staff](#staff)
- [store](#store)

**Junction Tables:**

- [film_actor](#film_actor)
- [film_category](#film_category)

**Location Tables:**

- [address](#address)
- [city](#city)
- [country](#country)

---

## actor

| Column      | Type                     | Nullable | Default        |
| ----------- | ------------------------ | -------- | -------------- |
| actor_id    | integer                  | NOT NULL | auto-increment |
| first_name  | text                     | NOT NULL |                |
| last_name   | text                     | NOT NULL |                |
| last_update | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `actor_id`  
**Indexes:** `idx_actor_last_name` on `last_name`  
**Referenced by:** `film_actor.actor_id`

---

## film

| Column               | Type                     | Nullable | Default        |
| -------------------- | ------------------------ | -------- | -------------- |
| film_id              | integer                  | NOT NULL | auto-increment |
| title                | text                     | NOT NULL |                |
| description          | text                     |          |                |
| release_year         | year                     |          |                |
| language_id          | integer                  | NOT NULL |                |
| original_language_id | integer                  |          |                |
| rental_duration      | smallint                 | NOT NULL | 3              |
| rental_rate          | numeric(4,2)             | NOT NULL | 4.99           |
| length               | smallint                 |          |                |
| replacement_cost     | numeric(5,2)             | NOT NULL | 19.99          |
| rating               | mpaa_rating              |          | 'G'            |
| last_update          | timestamp with time zone | NOT NULL | now()          |
| special_features     | text[]                   |          |                |
| fulltext             | tsvector                 | NOT NULL |                |

**Primary Key:** `film_id`  
**Indexes:** `idx_title` on `title`, `idx_fk_language_id`, `idx_fk_original_language_id`  
**Foreign Keys:**

- `language_id` → `language.language_id`
- `original_language_id` → `language.language_id`

**Referenced by:** `film_actor`, `film_category`, `inventory`

---

## category

| Column      | Type                     | Nullable | Default        |
| ----------- | ------------------------ | -------- | -------------- |
| category_id | integer                  | NOT NULL | auto-increment |
| name        | text                     | NOT NULL |                |
| last_update | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `category_id`  
**Referenced by:** `film_category.category_id`

---

## language

| Column      | Type                     | Nullable | Default        |
| ----------- | ------------------------ | -------- | -------------- |
| language_id | integer                  | NOT NULL | auto-increment |
| name        | character(20)            | NOT NULL |                |
| last_update | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `language_id`  
**Referenced by:** `film.language_id`, `film.original_language_id`

---

## customer

| Column      | Type                     | Nullable | Default        |
| ----------- | ------------------------ | -------- | -------------- |
| customer_id | integer                  | NOT NULL | auto-increment |
| store_id    | integer                  | NOT NULL |                |
| first_name  | text                     | NOT NULL |                |
| last_name   | text                     | NOT NULL |                |
| email       | text                     |          |                |
| address_id  | integer                  | NOT NULL |                |
| activebool  | boolean                  | NOT NULL | true           |
| create_date | date                     | NOT NULL | CURRENT_DATE   |
| last_update | timestamp with time zone |          | now()          |
| active      | integer                  |          |                |

**Primary Key:** `customer_id`  
**Indexes:** `idx_last_name` on `last_name`, `idx_fk_store_id`, `idx_fk_address_id`  
**Foreign Keys:**

- `store_id` → `store.store_id`
- `address_id` → `address.address_id`

**Referenced by:** `rental`, `payment`

---

## rental

| Column       | Type                     | Nullable | Default        |
| ------------ | ------------------------ | -------- | -------------- |
| rental_id    | integer                  | NOT NULL | auto-increment |
| rental_date  | timestamp with time zone | NOT NULL |                |
| inventory_id | integer                  | NOT NULL |                |
| customer_id  | integer                  | NOT NULL |                |
| return_date  | timestamp with time zone |          |                |
| staff_id     | integer                  | NOT NULL |                |
| last_update  | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `rental_id`  
**Indexes:** `idx_fk_inventory_id`, unique on `(rental_date, inventory_id, customer_id)`  
**Foreign Keys:**

- `customer_id` → `customer.customer_id`
- `inventory_id` → `inventory.inventory_id`
- `staff_id` → `staff.staff_id`

**Referenced by:** `payment.rental_id`

---

## payment

**Note:** This is a partitioned table (by payment_date, monthly partitions).

| Column       | Type                     | Nullable | Default        |
| ------------ | ------------------------ | -------- | -------------- |
| payment_id   | integer                  | NOT NULL | auto-increment |
| customer_id  | integer                  | NOT NULL |                |
| staff_id     | integer                  | NOT NULL |                |
| rental_id    | integer                  | NOT NULL |                |
| amount       | numeric(5,2)             | NOT NULL |                |
| payment_date | timestamp with time zone | NOT NULL |                |

**Primary Key:** `(payment_date, payment_id)`  
**Foreign Keys:**

- `customer_id` → `customer.customer_id`
- `staff_id` → `staff.staff_id`
- `rental_id` → `rental.rental_id`

---

## inventory

| Column       | Type                     | Nullable | Default        |
| ------------ | ------------------------ | -------- | -------------- |
| inventory_id | integer                  | NOT NULL | auto-increment |
| film_id      | integer                  | NOT NULL |                |
| store_id     | integer                  | NOT NULL |                |
| last_update  | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `inventory_id`  
**Indexes:** `idx_store_id_film_id` on `(store_id, film_id)`  
**Foreign Keys:**

- `film_id` → `film.film_id`
- `store_id` → `store.store_id`

**Referenced by:** `rental.inventory_id`

---

## staff

| Column      | Type                     | Nullable | Default        |
| ----------- | ------------------------ | -------- | -------------- |
| staff_id    | integer                  | NOT NULL | auto-increment |
| first_name  | text                     | NOT NULL |                |
| last_name   | text                     | NOT NULL |                |
| address_id  | integer                  | NOT NULL |                |
| email       | text                     |          |                |
| store_id    | integer                  | NOT NULL |                |
| active      | boolean                  | NOT NULL | true           |
| username    | text                     | NOT NULL |                |
| password    | text                     |          |                |
| last_update | timestamp with time zone | NOT NULL | now()          |
| picture     | bytea                    |          |                |

**Primary Key:** `staff_id`  
**Foreign Keys:**

- `address_id` → `address.address_id`
- `store_id` → `store.store_id`

**Referenced by:** `rental`, `payment`

---

## store

| Column           | Type                     | Nullable | Default        |
| ---------------- | ------------------------ | -------- | -------------- |
| store_id         | integer                  | NOT NULL | auto-increment |
| manager_staff_id | integer                  | NOT NULL |                |
| address_id       | integer                  | NOT NULL |                |
| last_update      | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `store_id`  
**Indexes:** unique on `manager_staff_id`  
**Foreign Keys:**

- `address_id` → `address.address_id`

**Referenced by:** `customer`, `inventory`, `staff`

---

## film_actor

**Junction table** linking films to actors (many-to-many).

| Column      | Type                     | Nullable | Default |
| ----------- | ------------------------ | -------- | ------- |
| actor_id    | integer                  | NOT NULL |         |
| film_id     | integer                  | NOT NULL |         |
| last_update | timestamp with time zone | NOT NULL | now()   |

**Primary Key:** `(actor_id, film_id)`  
**Indexes:** `idx_fk_film_id`  
**Foreign Keys:**

- `actor_id` → `actor.actor_id`
- `film_id` → `film.film_id`

---

## film_category

**Junction table** linking films to categories (many-to-many).

| Column      | Type                     | Nullable | Default |
| ----------- | ------------------------ | -------- | ------- |
| film_id     | integer                  | NOT NULL |         |
| category_id | integer                  | NOT NULL |         |
| last_update | timestamp with time zone | NOT NULL | now()   |

**Primary Key:** `(film_id, category_id)`  
**Foreign Keys:**

- `film_id` → `film.film_id`
- `category_id` → `category.category_id`

---

## address

| Column      | Type                     | Nullable | Default        |
| ----------- | ------------------------ | -------- | -------------- |
| address_id  | integer                  | NOT NULL | auto-increment |
| address     | text                     | NOT NULL |                |
| address2    | text                     |          |                |
| district    | text                     | NOT NULL |                |
| city_id     | integer                  | NOT NULL |                |
| postal_code | text                     |          |                |
| phone       | text                     | NOT NULL |                |
| last_update | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `address_id`  
**Indexes:** `idx_fk_city_id`  
**Foreign Keys:**

- `city_id` → `city.city_id`

**Referenced by:** `customer`, `staff`, `store`

---

## city

| Column      | Type                     | Nullable | Default        |
| ----------- | ------------------------ | -------- | -------------- |
| city_id     | integer                  | NOT NULL | auto-increment |
| city        | text                     | NOT NULL |                |
| country_id  | integer                  | NOT NULL |                |
| last_update | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `city_id`  
**Indexes:** `idx_fk_country_id`  
**Foreign Keys:**

- `country_id` → `country.country_id`

**Referenced by:** `address.city_id`

---

## country

| Column      | Type                     | Nullable | Default        |
| ----------- | ------------------------ | -------- | -------------- |
| country_id  | integer                  | NOT NULL | auto-increment |
| country     | text                     | NOT NULL |                |
| last_update | timestamp with time zone | NOT NULL | now()          |

**Primary Key:** `country_id`  
**Referenced by:** `city.country_id`

---

## Entity Relationship Summary

**Film Management:**

```
film ←→ film_actor ←→ actor
film ←→ film_category ←→ category
film → language
film → inventory
```

**Store Operations:**

```
store → inventory → rental → payment
store → customer → rental → payment
store → staff → rental/payment
```

**Location Hierarchy:**

```
country → city → address → customer/staff/store
```

---

**Generated:** 2025-01-02  
**Database:** Pagila (DVD Rental Sample Database)
