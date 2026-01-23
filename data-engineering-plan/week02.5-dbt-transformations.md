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

---

#### Step 1: Create Your First Staging Model (10 min)

**What are staging models?**
Staging models are your "cleaned" raw data layer. They:

- Select only the columns you need
- Rename confusing column names
- Add simple transformations (like concatenating names)
- Reference raw tables using `source()`

**Create** `models/staging/stg_customers.sql`:

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

**What's happening here?**

- `{{ source('public', 'customer') }}` tells dbt "use the raw `customer` table from the `public` schema"
- This Jinja syntax will be replaced with `public.customer` when dbt runs
- We're adding `full_name` as a computed column (simple transformation)
- dbt will create a table or view called `stg_customers` in your `analytics` schema

**Now create two more staging models:**

`models/staging/stg_rentals.sql`:

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

`models/staging/stg_payments.sql`:

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

---

#### Step 2: Define Your Sources (5 min)

**What's a source definition?**
Before dbt can use `{{ source('public', 'customer') }}`, you need to tell it where to find these tables.

**Create** `models/staging/schema.yml`:

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

**What's this doing?**

- Tells dbt: "when I write `source('public', 'customer')`, look for `pagila.public.customer`"
- This makes your SQL portable (change database/schema in one place)
- dbt uses this to build a lineage graph showing where your data comes from

---

#### Step 3: Run Your Staging Models (5 min)

**Time to see dbt in action!**

```bash
dbt run --select staging
```

**What you should see:**

```
Running with dbt=1.x.x
Found 3 models, 0 tests, 0 snapshots...

Concurrency: 4 threads

15:23:45 | 1 of 3 START sql table model analytics.stg_customers ......... [RUN]
15:23:45 | 2 of 3 START sql table model analytics.stg_rentals ........... [RUN]
15:23:45 | 3 of 3 START sql table model analytics.stg_payments .......... [RUN]
15:23:46 | 1 of 3 OK created sql table model analytics.stg_customers .... [SUCCESS]
15:23:46 | 2 of 3 OK created sql table model analytics.stg_rentals ...... [SUCCESS]
15:23:46 | 3 of 3 OK created sql table model analytics.stg_payments ..... [SUCCESS]

Completed successfully
```

**What just happened?**

- dbt read your `.sql` files
- Executed `CREATE TABLE analytics.stg_customers AS (your SELECT statement)`
- Did the same for `stg_rentals` and `stg_payments`
- All three ran in parallel (notice the threading)

**Verify in psql:**

```bash
psql pagila -c "\dt analytics.*"
```

You should see your three new tables!

```bash
psql pagila -c "SELECT * FROM analytics.stg_customers LIMIT 5;"
```

You should see your data with the new `full_name` column.

---

#### Step 4: Create a Mart Model (Business Logic Layer) (15 min)

**What are marts?**
Marts are where you put **business logic**. They:

- Join multiple staging tables together
- Apply complex transformations and aggregations
- Create metrics and KPIs
- Use `ref()` to reference other dbt models (not raw tables!)

**Create** `models/marts/customer_lifetime_value.sql`:

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

**What's different here?**

- We use `{{ ref('stg_payments') }}` instead of `source()` because we're referencing **other dbt models**, not raw tables
- dbt knows `stg_payments` must run **before** `customer_lifetime_value` (dependency graph!)
- This model creates business metrics: total spend, segmentation, etc.
- Two CTEs organize the logic clearly (you already know CTEs from Week 1!)

**Key concept: `source()` vs `ref()`**

- `source('schema', 'table')` → raw database tables (use in staging)
- `ref('model_name')` → other dbt models (use in marts)

---

#### Step 5: Run the Full Pipeline (5 min)

```bash
dbt run
```

**What you should see:**

```
15:30:12 | 1 of 4 START sql table model analytics.stg_customers ......... [RUN]
15:30:12 | 2 of 4 START sql table model analytics.stg_rentals ........... [RUN]
15:30:12 | 3 of 4 START sql table model analytics.stg_payments .......... [RUN]
15:30:13 | 1 of 4 OK created sql table model analytics.stg_customers .... [SUCCESS]
15:30:13 | 2 of 4 OK created sql table model analytics.stg_rentals ...... [SUCCESS]
15:30:13 | 3 of 4 OK created sql table model analytics.stg_payments ..... [SUCCESS]
15:30:13 | 4 of 4 START sql table model analytics.customer_lifetime_value [RUN]
15:30:14 | 4 of 4 OK created sql table model analytics.customer_lifetime_value [SUCCESS]

Completed successfully
```

**Notice:**

- The three staging models ran **first** (in parallel)
- `customer_lifetime_value` ran **after** (it depends on staging models)
- dbt figured out the correct order automatically!

**Verify your mart:**

```bash
psql pagila -c "SELECT customer_id, full_name, total_rentals, total_paid, customer_segment FROM analytics.customer_lifetime_value ORDER BY total_paid DESC LIMIT 10;"
```

You should see your top 10 customers with their lifetime value and segment!

---

#### Step 6: Understand What You Just Built (Reflection)

**You now have a mini data pipeline:**

1. **Raw Data** → `public.customer`, `public.rental`, `public.payment`
2. **Staging Layer** → `analytics.stg_*` (cleaned, standardized)
3. **Mart Layer** → `analytics.customer_lifetime_value` (business metrics)

**Key benefits over raw SQL:**

- **Version control:** All transformations are in `.sql` files you can commit to git
- **Dependencies:** dbt runs models in the right order automatically
- **Modularity:** Change `stg_customers` and all downstream models update
- **Documentation:** You can add descriptions and tests (coming in Day 2!)

**Compare to your Week 1/2 work:**

- Your complex SQL queries from Week 2 Day 5? Those could be dbt marts!
- Instead of one giant query, you'd break it into staging → intermediate → final mart
- Much easier to debug, test, and maintain

---

### Day 2 – Tests, Documentation, and Lineage

**Goal:** Learn how to validate your data transformations and document your work. This is where dbt shines compared to raw SQL scripts!

**Study (10 min)**

- Read dbt docs on [tests](https://docs.getdbt.com/docs/build/tests) and [documentation](https://docs.getdbt.com/docs/build/documentation).

---

#### Step 1: Understand dbt Tests (Concept - 5 min)

**Why test your data?**
In Weeks 1 & 2, you wrote SQL queries and assumed the data was correct. But:

- What if `customer_id` has duplicates?
- What if `email` is NULL?
- What if a payment references a customer that doesn't exist?

**dbt tests automatically check these assumptions!**

**Two types of tests:**

1. **Generic tests** (built-in): `unique`, `not_null`, `accepted_values`, `relationships`
2. **Custom tests** (you write SQL): "Return rows that fail the test"

If tests fail → you know your data has issues!

---

#### Step 2: Add Generic Tests to Staging Models (15 min)

**Update** `models/staging/schema.yml` (add the `models:` section):

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
              arguments:
                to: ref('stg_customers')
                field: customer_id
```

**What do these tests check?**

- `unique`: No duplicate values (e.g., `customer_id` should be unique)
- `not_null`: No NULL values
- `relationships`: Foreign key constraint (every `customer_id` in payments exists in customers)

**The `relationships` test is powerful:**

```yaml
- relationships:
    arguments:
      to: ref('stg_customers')
      field: customer_id
```

This translates to SQL:

```sql
SELECT * FROM stg_payments p
WHERE NOT EXISTS (
  SELECT 1 FROM stg_customers c
  WHERE c.customer_id = p.customer_id
)
```

If this returns rows → test fails (orphaned payments!)

---

#### Step 3: Run Your Tests (5 min)

```bash
dbt test
```

**What you should see:**

```
15:45:12 | 1 of 8 START test not_null_stg_customers_customer_id ......... [RUN]
15:45:12 | 2 of 8 START test not_null_stg_customers_email ............... [RUN]
15:45:12 | 3 of 8 START test not_null_stg_customers_store_id ............ [RUN]
15:45:12 | 4 of 8 START test not_null_stg_payments_amount ............... [RUN]
15:45:12 | 5 of 8 START test not_null_stg_payments_payment_id ........... [RUN]
15:45:12 | 6 of 8 START test unique_stg_customers_customer_id ........... [RUN]
15:45:12 | 7 of 8 START test unique_stg_payments_payment_id ............. [RUN]
15:45:12 | 8 of 8 START test relationships_stg_payments_customer_id ..... [RUN]
15:45:13 | 1 of 8 PASS not_null_stg_customers_customer_id ............... [PASS]
15:45:13 | 2 of 8 PASS not_null_stg_customers_email ..................... [PASS]
... (all PASS)

Completed successfully
```

**If a test fails:**

```
15:45:13 | 8 of 8 FAIL 2 relationships_stg_payments_customer_id ......... [FAIL 2]
```

The number (2) tells you how many rows failed the test!

**To debug a failing test:**

```bash
dbt test --select stg_payments
```

Then check the compiled SQL in `target/compiled/pagila_analytics/models/staging/schema.yml/`

---

#### Step 4: Add a Custom Test (10 min)

**Generic tests are great, but sometimes you need custom logic.**

**Create** `tests/assert_positive_amounts.sql`:

```sql
-- This test will fail if there are any negative payment amounts
SELECT
    payment_id,
    amount
FROM {{ ref('stg_payments') }}
WHERE amount < 0
```

**How custom tests work:**

- Write a `SELECT` query that **returns rows that fail the test**
- If the query returns 0 rows → test passes ✅
- If it returns any rows → test fails ❌ (dbt shows you the failing rows!)

**This is like your data quality checks from Week 2!**
Remember finding quirks in Pagila? (store_id = 0, payment dates ≠ rental dates)
You could write custom tests for those discoveries:

```sql
-- Test: rental_date should always be before or equal to payment_date
SELECT
    r.rental_id,
    r.rental_date,
    p.payment_date
FROM {{ ref('stg_rentals') }} r
JOIN {{ ref('stg_payments') }} p USING (rental_id)
WHERE p.payment_date < r.rental_date
```

**Run your tests again:**

```bash
dbt test
```

You should now see your custom test in the output!

---

#### Step 5: Generate Documentation (10 min)

**dbt can auto-generate a searchable website with:**

- All your models and their columns
- Test results
- **Lineage graphs** (visual DAG showing data flow)

**Generate the docs:**

```bash
dbt docs generate
dbt docs serve
```

**What you should see:**

```
Serving docs at 8080
To access from your browser, navigate to: http://localhost:8080
```

**Open the link in your browser!**

**Explore:**

1. **Project tab**: See all your models organized by folder
2. **Search bar**: Find any model or column instantly
3. **Click on `customer_lifetime_value`**:
   - See the SQL code
   - See all column descriptions
   - Click the **"Lineage" button** (bottom right) 🎯

**The lineage graph shows:**

- `public.customer` → `stg_customers` → `customer_lifetime_value`
- `public.payment` → `stg_payments` → `customer_lifetime_value`
- `public.rental` → `stg_rentals` → `customer_lifetime_value`

**This is the data lineage!** You can see:

- Where each model gets its data from (upstream dependencies)
- What models depend on it (downstream impact)

**Why this matters:**
If you change `stg_customers`, you can instantly see that `customer_lifetime_value` will be affected!

---

#### Step 6: Add Better Descriptions (10 min)

**Right now your docs are bare-bones. Let's make them useful for a colleague (or future you!).**

**Create** `models/marts/schema.yml`:

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
      - name: total_rentals
        description: "Count of distinct rental transactions"
      - name: avg_payment
        description: "Average payment amount per transaction"
      - name: first_payment_date
        description: "Date of customer's first payment (proxy for acquisition date)"
      - name: last_payment_date
        description: "Date of customer's most recent payment (recency metric)"
```

**Regenerate docs to see your changes:**

```bash
dbt docs generate
dbt docs serve
```

Refresh the browser and click on `customer_lifetime_value` again. Much better!

---

#### Step 7: Reflection (What You Learned)

**Compare to Weeks 1 & 2:**

| Week 1/2 Approach               | dbt Approach                             |
| ------------------------------- | ---------------------------------------- |
| Write query in `.sql` file      | Write model in `.sql` file ✅ Same!      |
| Run manually in psql            | `dbt run` (runs all models in order)     |
| Hope the data is correct 🤞     | `dbt test` (validates assumptions)       |
| Comment your SQL                | Auto-generated docs website with lineage |
| Find downstream impact manually | Click "Lineage" to see impact instantly  |

**Key insight:**
Tests are **executable documentation**. Instead of writing "customer_id should be unique" in a comment, you write it as a test that runs every time!

**Real-world scenario:**

- Your teammate changes `stg_customers` (adds a filter, deduplication logic, etc.)
- They run `dbt test` → sees that `customer_lifetime_value` tests fail
- They know they broke something **before** pushing to production!

This is the power of data testing. 🎯

---

### Day 3 – Advanced Models & Macros

**Goal:** Level up with more complex transformations, reusable code (macros), and incremental models. This day connects your Week 2 advanced SQL skills with dbt patterns.

**Study (10 min)**

- Read about [Jinja and Macros](https://docs.getdbt.com/docs/build/jinja-macros)
- Read about [Incremental Models](https://docs.getdbt.com/docs/build/incremental-models)

---

#### Step 1: Build a Complex Mart (20 min)

**This is like your Week 2 Day 4/5 queries!** Multiple CTEs, joins, aggregations.

**Create** `models/marts/category_performance.sql`:

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

**What's happening here?**

- **Three CTEs** organize the logic (you're already comfortable with this from Week 1!)
- `{{ source() }}` for raw tables, `{{ ref() }}` for dbt models (staging)
- `NULLIF(SUM(...), 0)` prevents division by zero (data quality pattern from Week 2!)
- This is essentially "Week 2 Day 3 Task 3" reimagined as a dbt mart

**Run it:**

```bash
dbt run --select category_performance
```

**Verify:**

```bash
psql pagila -c "SELECT * FROM analytics.category_performance ORDER BY total_revenue DESC LIMIT 5;"
```

You should see which film categories generate the most revenue!

---

#### Step 2: Create a Macro (Reusable Code) (15 min)

**Problem:** You often need to round dollar amounts. Instead of writing `ROUND(amount::NUMERIC, 2)` everywhere, let's make it reusable!

**What's a macro?**
A macro is like a SQL function you can call in any model. Think of it as "DRY" (Don't Repeat Yourself) for SQL.

**Create** `macros/cents_to_dollars.sql`:

```sql
{% macro cents_to_dollars(column_name, precision=2) %}
    ROUND({{ column_name }}::NUMERIC, {{ precision }})
{% endmacro %}
```

**How to use it:**

Update `models/marts/customer_lifetime_value.sql` to use the macro:

```sql
SELECT
    c.customer_id,
    c.full_name,
    -- ... other columns ...
    {{ cents_to_dollars('p.total_paid') }} AS total_paid,
    {{ cents_to_dollars('p.avg_payment') }} AS avg_payment,
    -- ... rest of query ...
```

**What happens when dbt compiles this?**

The Jinja `{{ cents_to_dollars('p.total_paid') }}` becomes:

```sql
ROUND(p.total_paid::NUMERIC, 2) AS total_paid
```

**Run and verify:**

```bash
dbt run --select customer_lifetime_value
```

Check `target/compiled/pagila_analytics/models/marts/customer_lifetime_value.sql` to see the compiled SQL!

**When to use macros:**

- Date formatting logic used across models
- Complex CASE statements you reuse
- Custom data type conversions
- Any SQL snippet you copy-paste multiple times

---

#### Step 3: Incremental Models (Efficiency for Large Data) (25 min)

**Problem:** Right now, every `dbt run` rebuilds **all** tables from scratch. For large datasets (millions of rows), this is slow and expensive!

**Solution:** Incremental models only process **new** data since the last run.

**Create** `models/marts/rental_facts_incremental.sql`:

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

**What's happening here?**

1. **Config block:**

   ```sql
   {{
     config(
       materialized='incremental',
       unique_key='rental_id'
     )
   }}
   ```

   - `materialized='incremental'`: Don't rebuild the whole table, just add new rows
   - `unique_key='rental_id'`: If a row with this key exists, update it (upsert behavior)

2. **The `is_incremental()` check:**
   ```sql
   {% if is_incremental() %}
       WHERE r.rental_date > (SELECT MAX(rental_date) FROM {{ this }})
   {% endif %}
   ```
   - **First run:** `is_incremental()` is False → builds full table
   - **Subsequent runs:** `is_incremental()` is True → only processes new rentals
   - `{{ this }}` refers to the current model's table (i.e., `analytics.rental_facts_incremental`)

**Run it the first time (full build):**

```bash
dbt run --select rental_facts_incremental
```

**Output:**

```
16:30:12 | 1 of 1 START sql table model analytics.rental_facts_incremental [RUN]
16:30:13 | 1 of 1 OK created sql table model analytics.rental_facts_incremental [SUCCESS in 1.2s]
```

**Check the table:**

```bash
psql pagila -c "SELECT COUNT(*) FROM analytics.rental_facts_incremental;"
```

Let's say you get `16,044` rows.

**Run it again (incremental update):**

```bash
dbt run --select rental_facts_incremental
```

**Output:**

```
16:31:45 | 1 of 1 START sql incremental model analytics.rental_facts_incremental [RUN]
16:31:45 | 1 of 1 OK created sql incremental model analytics.rental_facts_incremental [SUCCESS in 0.1s]
```

Notice: **0.1s instead of 1.2s!** It only checked for new rentals (there are none in Pagila since it's static data).

**When to use incremental models:**

- Event/log data that grows over time (payments, clicks, transactions)
- Tables with millions+ rows where full rebuild is slow
- **Not for:** Small dimension tables (customers, products) that change infrequently

---

#### Step 4: Run Full Pipeline and Generate Docs (5 min)

```bash
dbt run
dbt test
dbt docs generate
dbt docs serve
```

**Check the lineage graph!**
You should now see:

- Your new `category_performance` mart
- Your `rental_facts_incremental` mart
- All connections between sources → staging → marts

---

#### Step 5: Homework Challenge (Week 2 Revisited) (30-60 min)

**Pick 2-3 of your hardest Week 2 queries and recreate them as dbt models.**

Suggestions:

- **Week 2 Day 4 Task 1** (Churn analysis) → `models/marts/customer_churn_monthly.sql`
- **Week 2 Day 5 Task 1** (Top customers with preferred category) → You already did this! That's basically `customer_lifetime_value.sql`
- **Week 2 Day 3 Task 1** (Customer segmentation) → Could be a new mart

**For each model:**

1. Add appropriate tests (uniqueness, not_null, etc.)
2. Add column descriptions in `schema.yml`
3. Use CTEs to break down complex logic
4. Use `{{ ref() }}` to reference staging models

**Reflection question:**

- Which version is easier to understand: the raw SQL file or the dbt model?
- If you needed to change the definition of "active customer," which version would be easier to update?

This is why companies adopt dbt! 🎯

---

#### Step 6: Reflection (What You've Mastered)

**You've now learned the core dbt workflow that data engineers use daily!**

**Day 1:** Built your first pipeline (staging → marts)
**Day 2:** Added data quality checks and documentation
**Day 3:** Used advanced features (macros, incremental models)

**Compare your Week 2 work to dbt:**

| Week 2 SQL Files               | dbt Project                                  |
| ------------------------------ | -------------------------------------------- |
| One giant query                | Broken into staging → marts (modular)        |
| Manual execution order         | `dbt run` handles dependencies automatically |
| No data validation             | Tests run every time (catch issues early)    |
| Comments in SQL                | Auto-generated docs website with lineage     |
| Hard to find downstream impact | Click "Lineage" to see everything            |
| Copy-paste repeated logic      | Macros make code reusable                    |

**The "aha!" moment:**
dbt turns your SQL queries into a **production-grade data pipeline** with testing, documentation, and version control.

**This is what analytics engineers do!** You're no longer just writing queries—you're building maintainable data products.

---

### Wrap-Up

By the end of this mini-week, you should:

- ✅ Understand how dbt organizes transformations (staging → marts)
- ✅ Be comfortable writing models with CTEs and `ref()`
- ✅ Know how to add tests and documentation
- ✅ Understand how lineage graphs help with impact analysis
- ✅ Have a working dbt project you can show to your team
- ✅ See the connection between your SQL skills and modern data tools

**Next steps in your journey:**

- **Week 3:** Data modeling and slowly changing dimensions (SCDs)
- **Week 5:** You'll use dbt with orchestration tools (Airflow/Dagster)
- **Real world:** dbt projects have 50-500+ models organized into layers

**Bonus:** Commit everything to git! (See the new version control guidance in the updated README.)

```bash
cd ~/learning
git add pagila_analytics/
git commit -m "feat: Add dbt project with staging and mart models"
git push
```

---

### Troubleshooting Common Issues

**Issue:** `dbt run` says "Compilation Error: Model 'stg_customers' depends on a source that does not exist"

- **Fix:** Make sure `models/staging/schema.yml` defines the `sources:` section

**Issue:** Tests fail with "Database Error: relation does not exist"

- **Fix:** Run `dbt run` before `dbt test` (tests need the models to exist first!)

**Issue:** `{{ ref('stg_payments') }}` has spaces → `{ { ref('stg_payments') } }`

- **Fix:** Disable SQL auto-formatting (see `.cursorrules` or settings)

**Issue:** Incremental model rebuilds every time instead of incrementing

- **Fix:** Check that `unique_key` is set and the `WHERE` clause in `is_incremental()` is correct

**Issue:** Lineage graph is empty or broken

- **Fix:** Make sure you're using `{{ source() }}` and `{{ ref() }}` (not hardcoded table names like `public.customer`)
