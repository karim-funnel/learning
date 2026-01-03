## Week 2 Callback Exercises - Revisit with Better Tools

**Purpose:** Now that you've learned window functions, revisit problems from Week 1 that were hard or impossible with basic SQL.

---

### Exercise 1: Top N Per Group (FROM WEEK 1 DAY 1 TASK 5) ⭐

**The Original Problem:**

> For each store, find the **top 5 customers by total amount they have paid**.  
> Show: store id, customer id, customer name, total paid.

**What You Did in Week 1:**

You solved it with a `UNION` approach:

```sql
-- Store 1 query
(SELECT ... WHERE store_id = 1 ORDER BY total_paid DESC LIMIT 5)
UNION
-- Store 2 query  
(SELECT ... WHERE store_id = 2 ORDER BY total_paid DESC LIMIT 5)
```

**The Problem:** Not scalable! What if you have 100 stores? 1000 stores?

**Your Insight:** _"This is too hard-codey for me... This is not scalable."_

---

### NOW: Solve It With Window Functions 🚀

**Your Challenge:**

Rewrite the Week 1 Day 1 Task 5 query using `ROW_NUMBER()` and `PARTITION BY` to get the top 5 customers per store **without** hard-coding store IDs.

**Hints (don't look until you try!):**

<details>
<summary>Hint 1: What function ranks rows?</summary>

Use `ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_paid DESC)`

</details>

<details>
<summary>Hint 2: How do you filter the ranks?</summary>

Put the window function in a subquery or CTE, then filter `WHERE rank <= 5`

</details>

<details>
<summary>Hint 3: Basic structure</summary>

```sql
WITH ranked_customers AS (
    SELECT 
        ...,
        ROW_NUMBER() OVER (...) as rank
    FROM ...
)
SELECT * FROM ranked_customers
WHERE rank <= 5;
```

</details>

---

### Expected Output:

```
customer_id | store_id | customer_full_name | total_paid | rank
------------|----------|--------------------|-----------:|-----
    148     |    1     | ELEANOR HUNT       |  216.54    |  1
    144     |    1     | CLARA SHAW         |  195.58    |  2
    459     |    1     | TOMMY COLLAZO      |  186.62    |  3
    468     |    1     | TIM CARY           |  175.61    |  4
    236     |    1     | MARCIA DEAN        |  175.58    |  5
    526     |    2     | KARL SEAL          |  221.55    |  1
    137     |    2     | RHONDA KENNEDY     |  194.61    |  2
    178     |    2     | MARION SNYDER      |  194.61    |  3
    469     |    2     | WESLEY BULL        |  177.60    |  4
    181     |    2     | ANA BRADLEY        |  174.66    |  5
```

Notice: 5 rows per store, automatically, regardless of how many stores exist!

---

### Bonus Challenges:

Once you solve the basic version:

1. **What if there's a tie?**  
   - Customer 137 and 178 both paid $194.61
   - Try `RANK()` vs `DENSE_RANK()` vs `ROW_NUMBER()` - what's the difference?

2. **Top 3 categories per store by revenue**  
   - Similar problem, different domain
   - Great practice for understanding PARTITION BY

3. **Running total per customer ordered by payment date**  
   - Use `SUM() OVER (PARTITION BY customer_id ORDER BY payment_date)`
   - This is called a "cumulative sum" or "running total"

---

### Why This Matters for Your Job:

In real data work, you'll constantly need "top N per group" queries:

- Top 5 products per category by sales
- Top 10 employees per department by performance score  
- Most recent transaction per customer
- Top 3 error types per service per day

The `UNION` approach doesn't scale. Window functions are **the** professional solution.

---

### When to Complete This:

✅ **After Week 2 Day 1** (you'll have learned `ROW_NUMBER()` and ranking)  
✅ **Before Week 2 Day 3** (to build intuition for more complex window functions)

---

### Reflection Questions After Solving:

1. How much simpler is the window function version vs your Week 1 UNION approach?
2. Would your Week 1 solution work if Pagila had 50 stores? How about the window function version?
3. What other "per group" problems from your actual job could you solve with this pattern?

---

**Remember:** The fact that you recognized the scalability issue in Week 1 shows you're thinking like a real engineer. Now you'll have the tools to solve it properly! 💪

