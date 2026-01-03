## Week 1 – Core ANSI SQL, Joins, Aggregations (Pagila)

**Goal:** Get fully comfortable with multi‑table joins, `GROUP BY`, `HAVING`, and basic query patterns on the Pagila database.

**Primary DB:** PostgreSQL + Pagila.

### Rules of the Week (What’s Allowed / Not)

- **Allowed (use freely)**

  - `SELECT`, `FROM`, `WHERE`, `ORDER BY`, `LIMIT`
  - Joins: `INNER`, `LEFT`, `RIGHT`, `FULL`
  - Aggregations: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`
  - `GROUP BY`, `HAVING`
  - Subqueries
  - **CTEs (`WITH`)** (introduced on Day 4, but you can use them earlier if you want)
  - `CASE` (optional; not required in Week 1)

- **Not expected in Week 1 (avoid unless you already know them)**

  - **Window functions** (`... OVER (...)`), e.g. `ROW_NUMBER`, `RANK`, running totals  
    (these are the focus of Week 2)

- **Discouraged**
  - `SELECT *` (except for quick exploration)

### Setup (Do this once, before Day 1)

1. Make sure PostgreSQL is installed and running locally.
2. From your shell:

```bash
createdb pagila
psql -d pagila -f /Users/karim.pichara/learning/pagila/pagila-schema.sql
psql -d pagila -f /Users/karim.pichara/learning/pagila/pagila-data.sql
```

3. Confirm it worked:

```bash
psql pagila
pagila=> \dt
```

You should see tables like `film`, `customer`, `rental`, `payment`, `store`, `inventory`, `actor`, `category`, etc.

### Reference Resources

- **Mode Analytics SQL Tutorial (free):** excellent visual explanations and practice
  - Start at: [Mode SQL Tutorial – Lessons 1–5](https://mode.com/sql-tutorial/introduction-to-sql/)
- **PostgreSQL docs:**
  - [SELECT](https://www.postgresql.org/docs/current/sql-select.html)
  - [FROM / JOIN](https://www.postgresql.org/docs/current/queries-table-expressions.html)

Aim to **skim the theory quickly, then spend most of your time in psql actually writing queries.**

---

### Day 1 – Exploring Pagila and Simple Joins

**Timebox:** 45–60 minutes.

- **Study (10–15 min)**

  - Read Mode tutorial: Lessons 1–3 (Intro, WHERE, GROUP BY).
  - In `psql`, explore:
    - `\d film`, `\d customer`, `\d rental`, `\d payment`, `\d store`, `\d inventory`.

- **Warm‑up queries (easy)**

  1. List the first 10 films with their title, release year, rental rate, and length.
  2. List the first 10 customers with their full name and email.

- **Homework – progressively harder**

Write SQL for each; **do not use `SELECT *`** unless explicitly allowed.

1. **Film–Language join (easy)**  
   Show the first 20 films with: film id, title, language name. (`film` + `language`).

2. **Film–Category join (medium)**  
   For each film in the _Action_ category, list: film title, category name, rental rate, replacement cost.  
   Tables to inspect: `film`, `category`, `film_category`.

3. **Customer–Store join (medium)**  
   List all customers with: customer id, full name, store id, and whether they are active.  
   Hint: look at `customer` and maybe `store` / `address`.

4. **Customer–Rental–Payment chain (harder)**  
   For the **first 50 rentals**, show:

   - rental id
   - rental date
   - customer full name
   - staff member who handled the rental
   - total amount paid for that rental (sum over `payment` rows)

   You will need to join: `rental`, `customer`, `staff`, `payment`.  
   Use `GROUP BY` over rental to get the total amount.

5. **Top customers by total payments per store (challenging)**  
   For each store, find the **top 5 customers by total amount they have paid**.  
   Show: store id, customer id, customer name, total paid.  
   Hints:
   - You’ll need `customer`, `store`, `payment`, and maybe `rental` / `inventory` (to link to store).
   - Start by writing a query that computes total paid per customer per store; then sort & limit per store (you can approximate by ordering and limiting globally if per‑store limiting is too much for now).

---

### Day 2 – Deep Dive into Joins (INNER, LEFT, RIGHT, FULL)

**Timebox:** 45–60 minutes.

- **Study (10–15 min)**

  - Mode tutorial: Lessons 6–8 (Joins).
  - Skim Postgres docs section on joins: [Table Expressions](https://www.postgresql.org/docs/current/queries-table-expressions.html).

- **Warm‑up (easy)**

  1. Get all films and their category name (if any). Use an `INNER JOIN`.
  2. Rewrite the same query as a `LEFT JOIN` and check if counts differ.

- **Homework**

1. **Customers without rentals (LEFT JOIN) – medium**  
   Find all customers who have **never rented a film**.

   - Show: customer id, full name, email, store id.
   - Use a `LEFT JOIN` from `customer` to `rental` and filter where rental is null.

2. **Films never rented (LEFT JOIN) – medium/hard**  
   Find all films that have **never been rented**.

   - Tables: `film`, `inventory`, `rental`.
   - Hint: a film might have multiple inventory rows, each of which may or may not have rentals.

3. **Customers and last rental date (LEFT JOIN + aggregation) – hard**  
   For every customer, show:

   - customer id, full name
   - total number of rentals
   - date of their **most recent rental** (null if they never rented)

4. **Stores and missing staff (RIGHT/FULL JOIN practice) – thinking question**  
   Try to write a query that lists all stores and the staff assigned to them, but also shows any staff who are not linked to a store (if that exists in data). Use a `FULL JOIN`.  
   Even if the dataset is “clean”, the exercise is about being comfortable writing the join.

---

### Day 3 – GROUP BY, HAVING, and Aggregations

**Timebox:** 45–60 minutes.

- **Study (10–15 min)**

  - Mode tutorial: Lesson on GROUP BY and HAVING.
  - Postgres docs on aggregates: [Aggregate Functions](https://www.postgresql.org/docs/current/functions-aggregate.html).

- **Warm‑up (easy)**

  1. Count how many films there are per rating (e.g., PG, R).
  2. Compute average rental rate and average replacement cost per rating.

- **Homework**

1. **Active customers per store (medium)**  
   For each store, show:

   - store id
   - number of active customers
   - number of inactive customers  
     Make this a single result set with one row per store and two separate counts.

2. **Top categories by revenue (hard)**  
   For each film category, calculate:

   - total revenue (sum of `payment.amount`)
   - total number of rentals in that category  
     Then show the **top 5 categories by revenue**.

3. **Staff performance (hard)**  
   For each staff member, compute:

   - total number of rentals they processed
   - total amount they collected in payments
   - average payment amount per rental they handled  
     Order by total amount collected descending.

4. **Customers with high average payment (HAVING, challenging)**  
   Find customers whose **average payment amount** is **above the overall average payment amount**.
   - Step 1: Compute overall average payment.
   - Step 2: Compute per‑customer average.
   - Step 3: Filter using `HAVING` and your step‑1 value (either hard‑code it, put it in a subquery, or use a CTE).

---

### Day 4 – Multi‑step Questions and CTEs (Intro)

**Timebox:** 45–60 minutes.

- **Study (10–15 min)**

  - Mode tutorial: Lesson on subqueries & CTEs.
  - Postgres docs: [WITH Queries (CTEs)](https://www.postgresql.org/docs/current/queries-with.html).

- **Warm‑up**

  1. Write a subquery that finds the **average film length** and then lists only films longer than that average.

- **Homework**

1. **Top customers per category (CTE, hard)**  
   For the **Comedy** category, find the **top 10 customers by total amount spent** on Comedy films.

   - Suggested structure:
     - CTE 1: join `film` + `category` + `film_category` to get all Comedy film inventory ids.
     - CTE 2: join rentals and payments to compute per‑customer totals for Comedy.
     - Final query: order and limit.

2. **High value “loyal” customers (hard)**  
   Define a “loyal” customer as someone who:

   - has rented more than 20 films **and**
   - whose **total payments** are in the top 20% of all customers.  
     Use a combination of CTEs and `HAVING` to identify them.

3. **Store health summary (challenging)**  
   Produce a small “dashboard” query with one row per store containing:
   - total number of customers
   - total rentals
   - total revenue (sum of payments)
   - revenue per customer
   - average rentals per customer  
     This is mainly about writing clear CTEs and aggregations.

---

### Day 5 – Mixed Review & Challenge Set

Use this day to **reinforce everything from the week**. No new reading required.

**Homework – choose at least 3, ideally all 5**

1. **Customer activity cohort (medium/hard)**  
   Group customers by the **year they first rented a film** and compute:

   - number of customers in the cohort
   - total revenue from that cohort
   - average revenue per customer in the cohort.

2. **Film profitability proxy (hard)**  
   Define a rough “profitability index” per film as:  
   \[
   \text{profitability} = \frac{\text{total revenue from rentals of that film}}{\text{replacement cost}}
   \]

   - Compute this for all films.
   - Show the top 20 films by this index, including film title, category, total revenue, replacement cost, and the computed index.

3. **Store inventory utilization (hard)**  
   For each store, compute **inventory utilization** as:  
   \[
   \text{utilization} = \frac{\text{number of rentals}}{\text{number of inventory items}}
   \]  
   Rank stores by utilization.

4. **Most “overdue‑prone” customers (challenging)**  
   Approximate overdue behavior by defining a rental as overdue if `return_date` is more than 5 days after `rental_date`.

   - For each customer, compute the percentage of their rentals that were overdue.
   - List the top 20 customers by this percentage (with at least 10 rentals total).

5. **Design your own question (meta‑challenge)**  
   Invent a **business question** that a DVD rental chain might ask (e.g., customer churn, underperforming genres, staff performance).
   - Write it down in plain English.
   - Write the SQL to answer it.
   - Keep both versions; they’re great practice for explaining your thinking.
