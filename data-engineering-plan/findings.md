## Pagila Database Findings

Quick notes about interesting quirks, patterns, and discoveries while working through the exercises.

---

### Data Quirks

**All customers have rentals**  
The Pagila database has 599 customers and all 599 have at least one rental. Week 1 Day 2 Task 1 (find customers without rentals) returns 0 rows. Query verified correct via test insert.

**No inactive customers by default**  
All customers have `activebool = true`. Had to manually set test customers to `activebool = false` to verify Task 1 Day 3 logic.

**Store IDs start from 0**  
Pagila has stores with IDs: 0, 1, 2, 3, 4. Most databases start from 1, but store_id = 0 is valid here.

**42 films never rented**  
Out of ~1000 films, 42 have never been rented (no inventory rental records across any copies).

**1500 staff but only 2 active**  
Pagila has 1500 staff records, but only staff_id 1 and 2 have processed rentals. The other 1498 appear to be inactive/test data.

**Films belong to multiple categories (many-to-many)**  
The `film_category` junction table creates many-to-many relationships. One film can appear in 2-3 categories (e.g., WITCHES PANIC is both Animation and Documentary). This means queries joining through film_category will show the same film multiple times, once per category.

---

### SQL Patterns Learned

**GROUP BY with primary keys**  
When grouping by a primary key (e.g., `rental_id`), PostgreSQL knows all other columns from that table are determined. Can GROUP BY `r.rental_id, c.customer_id, s.staff_id` instead of listing every column like `first_name, last_name`, etc.

**WHERE vs HAVING with LEFT JOINs**

- WHERE filters rows BEFORE grouping (removes evidence)
- HAVING filters groups AFTER grouping (considers all rows)
- Pattern: `LEFT JOIN ... GROUP BY ... HAVING COUNT(col) = 0` finds "never matched" records

**COUNT() ignores NULLs**  
`COUNT(column)` only counts non-NULL values. This is why `HAVING COUNT(r.rental_id) = 0` works for finding films with no rentals.

**Boolean to integer casting**  
PostgreSQL trick: `activebool::int` converts TRUE→1, FALSE→0. Allows `SUM(activebool::int)` to count active customers without CASE statements.

**SQL execution order - aliases in HAVING vs ORDER BY**  
SQL executes in order: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY.

- Can't use SELECT aliases in HAVING (alias doesn't exist yet - must repeat aggregate function)
- CAN use SELECT aliases in ORDER BY (alias exists by then)
- Example: `SELECT AVG(amount) as avg_amt ... HAVING AVG(amount) > 5 ORDER BY avg_amt`

**Can't SELECT \* with GROUP BY**  
When using GROUP BY, every column in SELECT must either be in the GROUP BY clause or inside an aggregate function. `SELECT * FROM table GROUP BY col` fails unless you GROUP BY all columns.

**CTEs (Common Table Expressions) for readability**  
Use `WITH name AS (query)` to break complex queries into logical steps. CTEs can reference earlier CTEs, making code self-documenting. Example: `WITH customers AS (...), payments AS (...) SELECT * FROM customers JOIN payments`.

**CTEs execute once and are materialized**  
Each CTE runs once when first referenced, not every time it's used. This is important for performance - if you reference a CTE multiple times in final query, PostgreSQL doesn't re-run it.

**CTEs don't preserve ORDER BY**  
An `ORDER BY` inside a CTE definition is ignored - CTEs are unordered result sets. To get sorted output, use `ORDER BY` in the final SELECT statement that queries the CTE. Example: `WITH sorted AS (SELECT ... ORDER BY x) SELECT * FROM sorted` won't be sorted unless you add another `ORDER BY` to the final SELECT.

**Window functions keep all rows (vs GROUP BY which collapses)**  
Window functions compute aggregates or rankings but return every input row. GROUP BY collapses rows into groups. Pattern: use window functions when you need "show me each row WITH context about its group."

**PARTITION BY creates independent ranking groups**  
`RANK() OVER (PARTITION BY category ORDER BY revenue DESC)` ranks items separately within each category. Ranks reset to 1 for each partition. Same item can have different ranks in different partitions (e.g., a film ranked #1 in Action, #3 in Comedy).

**Can use aggregates in window function ORDER BY**  
Pattern: `RANK() OVER (PARTITION BY store_id ORDER BY SUM(amount) DESC)` combines GROUP BY aggregation with window function ranking. Must GROUP BY first, then apply window function to the grouped results.

**Filter window function results with WHERE on the rank**  
Pattern: Use CTE with window function creating rank/row_number, then `WHERE rank <= N` in final SELECT to get "top N per group". Cannot use window function result directly in WHERE of same query.

**CASE statements for bucketing/segmentation**  
Use CASE to create categorical buckets from continuous data. Pattern: `CASE WHEN value < 50 THEN 'low' WHEN value BETWEEN 50 AND 150 THEN 'medium' ELSE 'high' END`. Common for customer segmentation, time of day analysis, and data binning. Remember: `BETWEEN` is inclusive on both ends, and CASE evaluates in order (stops at first match).

**Percentage calculation: aggregate / window aggregate**  
Advanced pattern: `100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY group_col)`. Combines GROUP BY aggregation with window function to calculate percentages within groups. The window function calculates the total per partition from already-grouped data. Use `100.0` (not `100`) to avoid integer division truncation.

**EXTRACT() for timestamp components**  
Use `EXTRACT(part FROM timestamp)` to get date/time components as integers. Common parts: `year`, `month`, `day`, `hour`, `minute`, `dow` (day of week 0-6). Alternative: `DATE_PART('part', timestamp)` in PostgreSQL. Standard SQL uses EXTRACT, more portable across databases.

**NULLIF for safe division**  
Prevent division by zero errors with `NULLIF(divisor, 0)`. Returns NULL if divisor is 0, otherwise returns divisor. Division by NULL returns NULL (not an error). Pattern: `value1 / NULLIF(value2, 0)`. Can wrap with `COALESCE(..., default)` to replace NULL results with a default value.

**COUNT(DISTINCT col) - Cardinality vs. Frequency**  
Use DISTINCT when counting unique entities, not occurrences. Mental model: "Check the box once per unique value." Signal words: "how many customers" (entities), "unique films", "different categories". Common scenario: one-to-many relationships where one entity does many things (one customer → many rentals). Without DISTINCT, counts each occurrence; with DISTINCT, counts each unique entity once. Pattern recognition: "Am I counting things or counting instances?" Things → DISTINCT, Instances → no DISTINCT. Example: Customer A with 5 rentals in Feb - `COUNT(customer_id)` = 5, `COUNT(DISTINCT customer_id)` = 1.

**DATE_TRUNC and TO_CHAR for time bucketing**  
For time series analysis, use `DATE_TRUNC('month', timestamp)` to get first day of month (keeps timestamp type), or `TO_CHAR(timestamp, 'YYYY-MM')` for text output. Always include year+month, not just month names, to avoid aggregating across years. Good practice even if data spans only one year. Common patterns: `DATE_TRUNC('day', ...)` for daily, `DATE_TRUNC('week', ...)` for weekly, `DATE_TRUNC('quarter', ...)` for quarterly analysis.

---

### Scalability Insights

**Top N per group is hard with basic SQL**  
Week 1 Day 1 Task 5 (top 5 customers per store) requires UNION with hard-coded store IDs. Doesn't scale beyond 2-3 groups. Window functions (Week 2) solve this properly with `ROW_NUMBER() OVER (PARTITION BY ...)`.

**LEFT JOIN + HAVING vs INNER JOIN performance**  
When you only want matched rows, INNER JOIN is faster than LEFT JOIN + HAVING filter. Example: `LEFT JOIN ... HAVING COUNT(col) > 0` processes all rows then filters, while `INNER JOIN` only processes matched rows from the start. On large datasets, INNER JOIN can be significantly faster.

---

### Query Organization

**One CTE = One concept**  
Best practice: each CTE should compute one logical thing (e.g., `customers_per_store`, `revenue_per_store`). Avoid cramming multiple calculations into one CTE. Makes debugging and understanding much easier.

**Derived metrics in separate CTEs**  
For calculated metrics (like revenue per customer), create a dedicated CTE that references base CTEs. Pattern: base metrics → derived metrics → final assembly. Keeps logic clear and testable.

---

### Testing Methodology

**0 rows doesn't mean wrong query**  
Always verify: is the query wrong, or does the data just not have matching cases? Use test inserts/updates to verify query logic works.

**Create test data to verify edge cases**  
When all data looks the same (e.g., all customers active), manually create edge cases to ensure query handles them correctly.

---

_Keep this file updated with interesting discoveries!_
