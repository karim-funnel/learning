## Week 4.5 – Substrait (Relational Plans & Interoperable Compute)

**Goal:** Go from "I know what Substrait is" → **upper beginner / early intermediate**: you can read a Substrait plan, relate it to SQL semantics (joins/filters/aggregations/windows), understand types/expressions, and validate/debug plans with the ecosystem tools.

**Time:** 5 days × 45–60 min/day.

---

### What is Substrait? (Start Here!)

**The Problem:**

When you write SQL, the database "compiles" it into a **query plan** - a tree of operations like:

```
Your SQL:
SELECT c.name, SUM(p.amount)
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
WHERE p.amount > 5
GROUP BY c.name

Becomes a plan:
Aggregate (group by: name, sum: amount)
  └─ Filter (amount > 5)
       └─ Join (customer.customer_id = payment.customer_id)
            ├─ Scan (customer)
            └─ Scan (payment)
```

**The Issue:** Every engine (Spark, DuckDB, Postgres, DataFusion, Velox) has its own plan format. They can't share plans!

**The Solution: Substrait**

Substrait is a **universal query plan format** - like a "common language" for query plans that any engine can:
- **Produce**: Convert SQL → Substrait plan
- **Consume**: Execute a Substrait plan

```
SQL → Substrait Plan → Any Engine
         ↓
   DuckDB, Spark, DataFusion, Velox, etc.
```

**Why Should You Care?**

1. **Portability**: Write a query once, run it anywhere
2. **Interoperability**: Mix engines in one pipeline (e.g., DuckDB for small data, Spark for big data)
3. **Debugging**: Inspect exactly what the engine is doing
4. **Understanding**: Deepens your knowledge of how SQL really works

**Real-World Use Cases:**

- **Ibis**: Python dataframe library that generates Substrait → runs on 10+ backends
- **DataFusion**: Rust query engine uses Substrait for federation
- **Velox**: Meta's execution engine consumes Substrait plans
- **DuckDB**: Can produce and consume Substrait
- **Your company**: If you ever need to move between query engines, Substrait helps!

**Connection to What You've Learned:**

| Your Learning | Connection to Substrait |
|---------------|------------------------|
| Week 1-2 SQL | Substrait represents SQL operations as a plan tree |
| Week 2.5 dbt | dbt compiles Jinja+SQL → SQL, but under the hood SQL → plan |
| Week 3 Star Schema | Fact/dim joins become Join operators in Substrait |
| Week 4 Distributed Compute | Spark's query plan is similar to Substrait concepts |

---

### Pre-requisites (Quick Setup)

**Option 1: Use Ibis (Recommended - Easiest)**

```bash
pip install ibis-framework[duckdb] substrait
```

This lets you write Python, generate Substrait plans, and execute them:

```python
import ibis

# Connect to DuckDB
con = ibis.duckdb.connect()

# Create a simple query
t = con.table("customer")
q = t.filter(t.active == True).select("customer_id", "first_name")

# Get the Substrait plan (proto bytes)
plan = ibis.to_substrait(q)
print(plan)  # Binary Substrait plan
```

**Option 2: Use the Substrait Validator (For reading plans)**

```bash
pip install substrait-validator
```

**Option 3: Just read example plans from the tutorial**

The [Substrait Tutorial](https://substrait.io/tutorial/) has example plans you can study without generating your own.

---

### Core Resources (Free)

- **Substrait home + spec** (start here): [Substrait](https://substrait.io/)
- **Tutorials (SQL → Substrait)**: [Substrait Tutorial](https://substrait.io/tutorial/)
- **Relations (operators like project/filter/join/aggregate)**: [Relations](https://substrait.io/relations/)
- **Expressions (functions, window functions, etc.)**: [Expressions](https://substrait.io/expressions/)
- **Types (type system used in plans)**: [Types](https://substrait.io/types/)
- **Serialization basics (text/binary forms)**: [Serialization](https://substrait.io/serialization/)
- **Tools (validator & related tooling)**: [Tools](https://substrait.io/tools/)
- **Spec repo (canonical reference)**: [`substrait-io/substrait`](https://github.com/substrait-io/substrait)

---

### Day 1 – Mental Model: “SQL is compiled into a plan”

**Study (15–20 min)**

- Read: [What is Substrait?](https://substrait.io/) and skim: [Relations basics](https://substrait.io/relations/).

**Practice (25–40 min)**

- Pick **one** Pagila query you’ve already written (Week 1/2). In a note, answer:
  - What are the core relational operators? (e.g., Scan → Filter → Join → Aggregate → Sort → Limit)
  - What is the **data flow** between operators?
  - What is the **grain** before and after the aggregate?

**Deliverable**

- A short “operator pipeline” description in plain English for your chosen SQL query.

---

### Day 2 – Types + Expressions (and why engines disagree)

**Study (15–20 min)**

- Skim: [Types](https://substrait.io/types/) and [Expressions](https://substrait.io/expressions/).

**Practice (25–40 min)**

- Take your Day 1 query and identify:
  - Which expressions are **scalar** vs **aggregate**.
  - Any implicit casts (e.g., integer division vs numeric division).
  - Any non-trivial expressions (e.g., `CASE`, `date_trunc`, string concatenation) that could be implemented differently across engines.

**Deliverable**

- A list of 5–10 expressions from your query categorized as scalar/aggregate and with their expected types.

---

### Day 3 – Reading and Validating Plans (text vs binary)

**Study (10–15 min)**

- Skim: [Serialization basics](https://substrait.io/serialization/) and look at the example structures.
- Skim: [Tools](https://substrait.io/tools/) and identify the **validator** and at least one "producer" tool.

**Practice (30–45 min)**

**How to get a plan to read:**

Option A - Use Ibis (if you set it up):
```python
import ibis
from ibis.formats.substrait import proto

con = ibis.duckdb.connect("path/to/your.duckdb")
t = con.table("payment")
q = t.filter(t.amount > 5).select("payment_id", "amount")

# Get the plan as a protobuf message
plan = ibis.to_substrait(q)

# Print as text (for human reading)
print(plan)
```

Option B - Use example plans from the tutorial:
- Go to [Substrait Tutorial Examples](https://substrait.io/tutorial/)
- Copy one of the example plan JSONs

**Then analyze the plan:**
- Locate the top-level relation tree
- Identify the join keys, filter predicate, grouping keys
- Find where expressions/functions are declared

**Deliverable**

- Annotate a plan (copy/paste into a note) with comments marking: scans, joins, filters, aggregates, sorts, limits.

---

### Day 4 – SQL → Substrait (Hands-on)

**Study (10–15 min)**

- Follow the official SQL → plan material: [Substrait Tutorial](https://substrait.io/tutorial/).

**Practice (30–45 min)**

**How to generate plans from your SQL:**

Using Ibis:
```python
import ibis

# Simple query (filter + join)
customers = con.table("customer")
payments = con.table("payment")

simple_q = (
    customers.join(payments, customers.customer_id == payments.customer_id)
    .filter(payments.amount > 5)
    .select("first_name", "amount")
)

# Hard query (aggregate)
hard_q = (
    payments.group_by("customer_id")
    .aggregate(total=payments.amount.sum(), count=payments.amount.count())
)

# Compare plans
print("=== SIMPLE PLAN ===")
print(ibis.to_substrait(simple_q))

print("=== HARD PLAN ===")
print(ibis.to_substrait(hard_q))
```

**Compare the two plans:**
- How does the Aggregate operator appear in the hard query?
- Whether filters are pushed "early" (before joins) or "late"
- How window functions appear (if supported): see [Expressions → Window Functions](https://substrait.io/expressions/)

**Deliverable**

- A short comparison note: "Query A plan vs Query B plan — 5 differences that matter."

---

### Day 5 – Mini Project: “Portable analytics plan”

**Goal:** Demonstrate you can reason about semantics independent of execution engine.

**Project options (pick 1)**

- **Option A (Plan-first):**
  - Start from a Substrait plan example and explain what SQL it corresponds to (at a high level).
  - Identify assumptions you’d need (types, null semantics, function definitions).

- **Option B (SQL-first):**
  - Pick one of your Pagila “hard” queries and generate a Substrait plan.
  - Write a short “semantics contract” describing expected behavior:
    - Join type and null handling
    - Aggregation grouping and measures
    - Window partition/order (if present)

**Deliverable**

- A 1–2 page markdown write-up you could show internally: “What Substrait is, why it matters, and a worked example.”

---

### How this integrates with the rest of the plan

- **After Week 4 (distributed compute/CAP/schemas):** Substrait gives you a concrete way to think about *how* compute is represented between systems.
- **Before Week 5 (pipelines/orchestration/logging):** you’ll have a stronger mental model for “what is a transformation step” and why cross-engine semantics matter.

