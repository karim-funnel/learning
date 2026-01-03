## Week 2 – Analytical SQL & Window Functions (Pagila)

**Goal:** Become comfortable with window functions, advanced filtering, and expressing complex analytical questions in SQL.

**Primary DB:** PostgreSQL + Pagila (same setup as Week 1).

### Rules of the Week (What’s Allowed / Not)

- **Allowed (use freely)**

  - Everything from Week 1 (joins, aggregates, `GROUP BY`/`HAVING`, subqueries, CTEs)
  - **Window functions** (`... OVER (...)`), including:
    - Ranking: `ROW_NUMBER`, `RANK`, `DENSE_RANK`
    - Bucketing: `NTILE`
    - Analytics: `SUM/AVG/MIN/MAX(...) OVER (...)`
    - Window frames (e.g., `ROWS BETWEEN ...`)
  - `CASE` (explicitly used in Day 3)

- **Not expected this week (avoid unless you already know them)**

  - Recursive CTEs (`WITH RECURSIVE`)
  - Procedural SQL / stored procedures (keep it in plain SQL queries)

- **Discouraged**
  - `SELECT *` (except for quick exploration)

### Reference Resources

- **Mode SQL Tutorial – Window Functions:**
  - [Intro to Window Functions](https://mode.com/sql-tutorial/sql-window-functions/)
  - [Ranking, Running Totals](https://mode.com/sql-tutorial/sql-window-functions/).
- **PostgreSQL docs – Window Functions:**
  - [Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html).

---

### Day 1 – Ranking and Row Number

**🔄 Callback from Week 1:** Remember Task 5 from Week 1 Day 1 (top customers per store)? You solved it with a UNION hack that wasn't scalable. Today you'll learn the proper way to solve "top N per group" problems! See `week02-callback-exercises.md` for a detailed revisit.

**Study (10–15 min)**

- Read Mode's intro to window functions and look at examples with `ROW_NUMBER`, `RANK`, `DENSE_RANK`.

**Warm‑up (easy/medium)**

1. For each film category, assign a `ROW_NUMBER` to films ordered by rental rate descending.
2. For each category, show the **top 3 most expensive** films by rental rate using `ROW_NUMBER` in a subquery.

**Homework**

1. **Top spenders per store (hard)**  
   Using window functions, find the **top 3 customers per store** by total amount paid.

   - Start by computing total paid per customer per store.
   - Then add a `RANK()` or `DENSE_RANK()` over `(PARTITION BY store_id ORDER BY total_paid DESC)`.
   - Filter to rank ≤ 3.

2. **Most profitable films per category (hard)**  
   Reuse your “profitability index” idea from Week 1 if you did it; otherwise define:  
   profitability = total revenue from that film.

   - Compute profitability per film, then use `RANK()` to get the **top 5 films per category**.
   - Show: category, film title, total revenue, rank.

3. **Customer payment rank within store (challenging)**  
   For each customer, compute:
   - total amount they’ve paid
   - their rank within their store by total paid
   - whether they are in the **top 10%** of customers in that store.  
     Hint: you may need both `RANK()` and `COUNT(*) OVER (PARTITION BY store_id)`.

---

### Day 2 – Running Totals and Moving Averages

**Study (10–15 min)**

- Read about `SUM(...) OVER (...)` and frame clauses in Mode / Postgres docs.

**Warm‑up**

1. Compute a **running total of payments over time** (order by payment date) across the entire business.

**Homework**

1. **Store‑level running revenue (medium/hard)**  
   For each store and date, compute:

   - total revenue for that day
   - running total revenue up to that day (per store).  
     Use `SUM(amount) OVER (PARTITION BY store_id ORDER BY date_trunc('day', payment_date))`.

2. **7‑day moving average of revenue (hard)**  
   On a per‑store basis, compute a **7‑day moving average** of daily revenue.  
   Use a window frame like `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW`.

3. **Customer spending trend (challenging)**  
   For each customer, compute the **running total** of how much they’ve spent over time ordered by payment date.  
   Then, for each customer, find the date on which they **crossed \$100 of cumulative spend** for the first time.

---

### Day 3 – Advanced Filtering, CASE, Conditional Aggregation

**Study (10–15 min)**

- Review `CASE` expressions in the Postgres docs.

**Warm‑up**

1. Write a query that buckets films into length buckets:
   - `< 60 min`, `60–90`, `90–120`, `> 120` and counts how many films fall into each bucket.

**Homework**

1. **Customer value segmentation (medium/hard)**  
   Segment customers into:

   - `low` (total payments < 50)
   - `medium` (50–150)
   - `high` (> 150).  
     Then produce a summary table that shows, for each store and each segment, how many customers there are and total revenue from that segment.

2. **Time‑of‑day analysis (hard)**  
   Bucket rentals by time of day (local time):

   - Morning (06:00–12:00), Afternoon (12:00–18:00), Evening (18:00–24:00), Night (00:00–06:00).  
     For each bucket, compute total rentals and total revenue. Use `CASE` on `rental_date`.

3. **Genre mix per store (challenging)**  
   For each store, compute the **distribution of rentals by category**.
   - Output one row per store & category with: total rentals, percentage of store’s rentals.
   - Use conditional aggregation or a window function to get the percentages.

---

### Day 4 – Complex CTE Chains and Re‑usable Patterns

**Study (10–15 min)**

- Re‑read CTE docs and think of CTEs as “named subqueries” for complex logic.

**Homework (each is substantial; 45–60 min total, pick at least 2)**

1. **Churn‑like analysis (hard)**  
   Define month‑level activity for customers:

   - a customer is **active** in a month if they rented at least 1 film.  
     Build a query (or set of CTEs) that:
   - computes, for each month, how many customers were active that month
   - how many were active this month but **not** active the previous month (re‑activated)
   - how many were active last month but **not** this month (approximate churn).  
     This is an excellent practice for date handling + joins + CTEs.
     Hint: use self-joins.

2. **Staff scheduling / workload analysis (hard)**  
   For each staff member and each month, compute:

   - total rentals handled
   - total revenue collected
   - their share of store revenue that month (percentage).  
     Then, for each staff member, find their **busiest month by rentals**.

3. **Multi‑step “business question” (challenging)**  
   Pick a business question that takes at least 3 logical steps to answer (e.g., “Which categories are growing the fastest in revenue over the last 6 months?”).
   - Write it down in English.
   - Implement using **at least 3 CTEs**, each representing a clear step.
   - Aim for readability more than “mega‑query cleverness”.

---

### Day 5 – Mini Project: Pagila Analytics Report

Use this day to simulate building a small **analytics report / dashboard** driven entirely by SQL.

**Deliverable:** One SQL script (or several queries) that produces a **coherent set of metrics** a DVD rental VP might care about.

Include at least:

- Overall revenue trend (daily or weekly) over time.
- Top 10 customers and their key stats (total spend, total rentals, preferred categories).
- Category performance (revenue, growth vs previous period).
- Store comparison: revenue, rentals, average rental value, utilization.

Stretch goals:

- Use window functions for trends (growth %, moving averages).
- Use CTEs heavily to keep the query organized.
- Save this script somewhere visible – you’ll reuse pieces later when we talk about OLAP and data modeling.
