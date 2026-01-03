## Week 2.5 – dbt: Transformations & Testing (3 Days)

**Goal:** Get hands-on with dbt to transform Pagila data and add tests. This bridges your SQL skills with modern analytics engineering practices.

**Why dbt?** It's the de-facto standard for transformation layers in modern data stacks, and it combines SQL with version control, testing, and documentation.

### Pre-requisites (If New to dbt - 45 min)

**Watch These First:**

- [What is dbt?](https://www.youtube.com/watch?v=M8oi7nSaWps) (10 min) - Official dbt Labs intro, very clear
- [dbt in 100 seconds](https://www.youtube.com/watch?v=5rNquRnNb4E) (2 min) - Quick overview

**Read Before Starting:**

- [dbt Quickstart](https://docs.getdbt.com/docs/get-started/getting-started/overview) (15 min) - Official tutorial, highly recommended
- [How we structure dbt projects](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview) (10 min) - Staging → marts pattern

**Key Mental Model:**

- Each `.sql` file in dbt = one `CREATE TABLE AS` or `CREATE VIEW AS`
- `{{ source('schema', 'table') }}` = reference raw database tables
- `{{ ref('model_name') }}` = reference other dbt models
- `dbt run` executes models in dependency order (builds your data pipeline)

**If Week 2.5 feels too fast:** Complete the [dbt Quickstart tutorial](https://docs.getdbt.com/docs/get-started/getting-started/overview) first, then return here.

---

### Reference Resources (Free)

- **dbt Core docs:**
  - [Getting Started](https://docs.getdbt.com/docs/introduction)
  - [Building Models](https://docs.getdbt.com/docs/build/models)
  - [Testing](https://docs.getdbt.com/docs/build/tests)
- **dbt Learn (free courses):**
  - [dbt Fundamentals](https://courses.getdbt.com/collections)

### Setup (Do this before Day 1)

**Install dbt-postgres:**

```bash
pip install dbt-core dbt-postgres
```

**Initialize a dbt project:**

```bash
cd ~/learning
dbt init pagila_analytics
cd pagila_analytics
```

**Configure `profiles.yml`:**

Edit `~/.dbt/profiles.yml` to connect to your Pagila database:

```yaml
pagila_analytics:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5432
      user: your_username
      pass: your_password # or use env var
      dbname: pagila
      schema: analytics
      threads: 4
```

**Test connection:**

```bash
dbt debug
```

You should see "All checks passed!"

**Create analytics schema:**

```bash
psql pagila
pagila=> CREATE SCHEMA IF NOT EXISTS analytics;
```

---

### Day 1 – First dbt Models (Staging & Marts)

**Study (15 min)**

- Read dbt docs sections on models and the recommended [staging → marts pattern](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview).

**Exercises (45 min)**

1. **Create staging models** in `models/staging/`:

   `stg_customers.sql`:

   ```sql
   SELECT
       customer_id,
       first_name,
       last_name,
       first_name || ' ' || last_name AS full_name,
       email,
       active,
       store_id,
       create_date,
       last_update
   FROM {{ source('public', 'customer') }}
   ```

   `stg_rentals.sql`:

   ```sql
   SELECT
       rental_id,
       rental_date,
       inventory_id,
       customer_id,
       return_date,
       staff_id,
       last_update
   FROM {{ source('public', 'rental') }}
   ```

   `stg_payments.sql`:

   ```sql
   SELECT
       payment_id,
       customer_id,
       staff_id,
       rental_id,
       amount,
       payment_date
   FROM {{ source('public', 'payment') }}
   ```

2. **Define sources** in `models/staging/schema.yml`:

   ```yaml
   version: 2

   sources:
     - name: public
       database: pagila
       schema: public
       tables:
         - name: customer
         - name: rental
         - name: payment
         - name: film
         - name: inventory
         - name: store
   ```

3. **Create a mart model** in `models/marts/`:

   `customer_lifetime_value.sql`:

   ```sql
   WITH customer_payments AS (
       SELECT
           customer_id,
           COUNT(DISTINCT rental_id) AS total_rentals,
           SUM(amount) AS total_paid,
           AVG(amount) AS avg_payment,
           MIN(payment_date) AS first_payment_date,
           MAX(payment_date) AS last_payment_date
       FROM {{ ref('stg_payments') }}
       GROUP BY customer_id
   ),

   customer_info AS (
       SELECT
           customer_id,
           full_name,
           email,
           store_id,
           active
       FROM {{ ref('stg_customers') }}
   )

   SELECT
       c.customer_id,
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
       END AS customer_segment
   FROM customer_info c
   LEFT JOIN customer_payments p USING (customer_id)
   ```

4. **Run your models:**

   ```bash
   dbt run
   ```

5. **Query your results:**

   ```bash
   psql pagila
   pagila=> SELECT * FROM analytics.customer_lifetime_value LIMIT 10;
   ```

---

### Day 2 – Tests, Documentation, and Lineage

**Study (10 min)**

- Read dbt docs on [tests](https://docs.getdbt.com/docs/build/tests) and [documentation](https://docs.getdbt.com/docs/build/documentation).

**Exercises (50 min)**

1. **Add tests** to `models/staging/schema.yml`:

   ```yaml
   version: 2

   sources:
     - name: public
       database: pagila
       schema: public
       tables:
         - name: customer
         - name: rental
         - name: payment

   models:
     - name: stg_customers
       description: "Staging table for customers with cleaned names"
       columns:
         - name: customer_id
           description: "Primary key"
           tests:
             - unique
             - not_null
         - name: email
           tests:
             - not_null
         - name: store_id
           tests:
             - not_null

     - name: stg_payments
       description: "Staging table for payments"
       columns:
         - name: payment_id
           tests:
             - unique
             - not_null
         - name: amount
           tests:
             - not_null
         - name: customer_id
           tests:
             - relationships:
                 to: ref('stg_customers')
                 field: customer_id
   ```

2. **Add a custom test** in `tests/assert_positive_amounts.sql`:

   ```sql
   -- This test will fail if there are any negative payment amounts
   SELECT
       payment_id,
       amount
   FROM {{ ref('stg_payments') }}
   WHERE amount < 0
   ```

3. **Run tests:**

   ```bash
   dbt test
   ```

4. **Generate documentation:**

   ```bash
   dbt docs generate
   dbt docs serve
   ```

   Open the browser link to explore your lineage graph!

5. **Add descriptions** to `models/marts/schema.yml`:

   ```yaml
   version: 2

   models:
     - name: customer_lifetime_value
       description: "Customer segmentation based on rental history and total spend"
       columns:
         - name: customer_id
           description: "Primary key"
         - name: total_paid
           description: "Sum of all payments from this customer"
         - name: customer_segment
           description: "Segmentation: low (<$50), medium ($50-$150), high (>$150)"
   ```

---

### Day 3 – Advanced Models & Macros

**Exercises (hard, 60 min)**

1. **Build a more complex mart:** `category_performance.sql`

   ```sql
   WITH film_categories AS (
       SELECT
           f.film_id,
           f.title,
           c.name AS category_name,
           f.rental_rate,
           f.replacement_cost
       FROM {{ source('public', 'film') }} f
       INNER JOIN {{ source('public', 'film_category') }} fc USING (film_id)
       INNER JOIN {{ source('public', 'category') }} c USING (category_id)
   ),

   rental_revenue AS (
       SELECT
           r.inventory_id,
           SUM(p.amount) AS total_revenue,
           COUNT(DISTINCT r.rental_id) AS rental_count
       FROM {{ ref('stg_rentals') }} r
       INNER JOIN {{ ref('stg_payments') }} p USING (rental_id)
       GROUP BY r.inventory_id
   ),

   inventory_films AS (
       SELECT
           inventory_id,
           film_id
       FROM {{ source('public', 'inventory') }}
   )

   SELECT
       fc.category_name,
       COUNT(DISTINCT fc.film_id) AS films_in_category,
       SUM(rr.rental_count) AS total_rentals,
       SUM(rr.total_revenue) AS total_revenue,
       AVG(rr.total_revenue) AS avg_revenue_per_film,
       SUM(rr.total_revenue) / NULLIF(SUM(rr.rental_count), 0) AS revenue_per_rental
   FROM film_categories fc
   LEFT JOIN inventory_films if USING (film_id)
   LEFT JOIN rental_revenue rr USING (inventory_id)
   GROUP BY fc.category_name
   ORDER BY total_revenue DESC
   ```

2. **Create a macro** in `macros/cents_to_dollars.sql`:

   ```sql
   {% macro cents_to_dollars(column_name, precision=2) %}
       ROUND({{ column_name }}::NUMERIC, {{ precision }})
   {% endmacro %}
   ```

   Use it in a model to demonstrate macro functionality.

3. **Add incremental loading** (conceptual exercise):

   Create `models/marts/rental_facts_incremental.sql`:

   ```sql
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
   ```

4. **Run everything and test:**

   ```bash
   dbt run
   dbt test
   dbt docs generate
   ```

5. **Homework challenge:**

   Recreate **2-3 of your hardest Week 2 SQL queries** as dbt models with appropriate tests. Compare the readability and maintainability.

---

### Wrap-Up

By the end of this mini-week, you should:

- Understand how dbt organizes transformations (staging → marts)
- Be comfortable writing models with CTEs and refs
- Know how to add tests and documentation
- Understand how lineage graphs help with impact analysis
- Have a working dbt project you can show to your team

**Bonus:** Commit everything to git! (See the new version control guidance in the updated README.)
