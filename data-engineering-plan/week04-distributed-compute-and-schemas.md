## Week 4 – Distributed Compute, CAP, Schemas (Avro/Thrift, Flexible vs Defined)

**Goal:** Build strong conceptual foundations around distributed data systems and data serialization formats.

### Reference Resources (Free)

- **Distributed systems & CAP (intro):**
  - Article: [CAP Theorem Explained (Cloud Native Glossary)](https://www.ibm.com/cloud/learn/cap-theorem).
  - Optional: [Designing Data‑Intensive Applications – free chapter snippets] or good blog summaries.
- **Distributed compute (Spark):**
  - Video (freeCodeCamp): *Apache Spark 3 – Complete Course for Beginners* on YouTube (you don’t need the whole thing; focus on concepts + a couple of demos).
  - Docs: [Spark Programming Guide](https://spark.apache.org/docs/latest/rdd-programming-guide.html) – skim the architecture section.
- **Schemas & serialization:**
  - Avro: [Apache Avro Getting Started](https://avro.apache.org/docs/current/getting-started/) – focus on schema definition examples.
  - Thrift: [Apache Thrift Tutorial](https://thrift.apache.org/tutorial/) – skim IDL examples.

---

### Day 1 – Distributed Compute Basics

**Study (20–25 min)**

- Watch the first ~20–30 minutes of the freeCodeCamp Spark course or a similar Spark intro that covers:
  - Why we need distributed processing.  
  - Basic Spark architecture (driver, executors, cluster manager).  
  - Transformations vs actions, lazy evaluation.

**Exercises (conceptual, medium)**

1. In a short note, answer:
   - When would you **not** need Spark (or any distributed engine)?  
   - What are clear signals that you **do** need distributed compute?
2. Describe how an analytical SQL query over a very large dataset might be executed in a distributed system (e.g., partitioning, shuffles) in 5–10 bullet points.

---

### Day 2 – CAP Theorem

**Study (15–20 min)**

- Read the CAP article carefully.

**Exercises (hard)**

1. For each pair (CP, AP, CA), list:
   - A type of real‑world system that is typically in that category.  
   - Why that choice makes sense for its use case.
2. Consider a data pipeline ingesting events in real time and serving both:
   - a **monitoring dashboard** (needs fresh data), and  
   - a **monthly financial report** (needs consistency).  
   Discuss in 5–10 bullet points how CAP trade‑offs might differ for these two consumers.

---

### Day 3 – Avro / Thrift Schemas

**Study (20 min)**

- Skim Avro Getting Started; focus on schema JSON examples.  
- Skim Thrift tutorial; look at IDL examples for structs and services.

**Exercises (medium/hard)**

1. **Design an Avro schema** for a `rental_event` similar to Pagila’s rental:
   - Include: event id, customer id, film id, store id, rental timestamp, return timestamp (nullable), price, currency, source system.  
   - Actually write the JSON Avro schema in a file or note.
2. **Design a Thrift struct** for `Customer` including nested `Address`.  
   - Think about required vs optional fields.
3. In a short comparison note, answer:
   - Main differences between Avro and Thrift in terms of: typical usage, schema evolution, language support.

---

### Day 4 – Flexible vs Defined Schemas

**Study (15–20 min)**

- Read 1–2 blog posts comparing schemaless (e.g., JSON in document stores) vs strongly typed schemas (Avro/Thrift/Protobuf, relational).

**Exercises (hard)**

1. Give **three scenarios** where flexible schema (e.g., JSON blobs) is a good idea, and three where it is a bad idea. Explain why in 2–3 sentences each.
2. For your Avro `rental_event` schema, imagine you need to add:
   - a new optional field `promo_code`  
   - a new required field `channel` (e.g., web, store, mobile).  
   Discuss how you’d evolve the schema while keeping backward and forward compatibility where possible.
3. Think about your current job: where do you see flexible schemas today? Where would a more strongly defined schema help with data quality or governance?

---

### Day 5 – File Formats (Parquet, CSV, JSON)

**Why This Matters:**

When processing data in pipelines, file format choice impacts:
- **Query performance** (100x difference between CSV and Parquet for analytical queries)
- **Storage costs** (compression can reduce size 10x)
- **Schema enforcement** (catch errors early vs late)
- **Interoperability** (which tools can read/write the format)

**Study (20–25 min)**

Key concepts to understand:

| Concept | Row-Based (CSV, JSON) | Columnar (Parquet, ORC) |
|---------|----------------------|------------------------|
| **Storage** | All columns together per row | Each column stored separately |
| **Best for** | Full row reads, small data | Aggregations, filtering specific columns |
| **Compression** | Poor (mixed data types) | Excellent (same type = better compression) |
| **Schema** | None (CSV) or loose (JSON) | Embedded in file header |

**Format Comparison:**

| Format | Schema | Compression | Use Case |
|--------|--------|-------------|----------|
| **CSV** | None | Poor | Data exchange, small files, human editing |
| **JSON** | Flexible | Moderate | APIs, configs, nested data |
| **Parquet** | Strong (embedded) | Excellent | Analytics, data lakes, Spark/DuckDB |
| **Avro** | Strong (separate) | Good | Kafka messages, streaming, schema evolution |
| **Iceberg** | Table format (on top of Parquet) | Excellent | ACID on data lakes, time travel |

**Parquet Deep Dive:**

```
Parquet file structure:
┌─────────────────────────────────┐
│ Row Group 1                     │
│   ├─ Column A (compressed)      │
│   ├─ Column B (compressed)      │
│   └─ Column C (compressed)      │
├─────────────────────────────────┤
│ Row Group 2                     │
│   ├─ Column A (compressed)      │
│   └─ ...                        │
├─────────────────────────────────┤
│ Footer (schema + metadata)      │
└─────────────────────────────────┘
```

Why columnar is fast for analytics:
- Query `SELECT AVG(amount)` only reads the `amount` column
- Skip entire row groups based on min/max statistics
- Compression is better when all values are the same type

**Exercises (hands-on with Polars)**

1. **Benchmark file formats:**

```python
import polars as pl
import time

# Create sample data (1M rows)
df = pl.DataFrame({
    "customer_id": range(1_000_000),
    "amount": [i * 0.01 for i in range(1_000_000)],
    "category": ["A", "B", "C", "D"] * 250_000,
})

# Write to different formats
df.write_csv("test.csv")
df.write_parquet("test.parquet")
df.write_json("test.json")

# Compare file sizes
import os
print(f"CSV: {os.path.getsize('test.csv') / 1024 / 1024:.2f} MB")
print(f"Parquet: {os.path.getsize('test.parquet') / 1024 / 1024:.2f} MB")
print(f"JSON: {os.path.getsize('test.json') / 1024 / 1024:.2f} MB")

# Compare read times (analytical query - only need one column)
start = time.time()
result = pl.read_csv("test.csv").select("amount").mean()
print(f"CSV read: {time.time() - start:.3f}s")

start = time.time()
result = pl.read_parquet("test.parquet").select("amount").mean()
print(f"Parquet read: {time.time() - start:.3f}s")
```

2. **Schema inspection:**

```python
# Parquet stores schema - inspect it
import pyarrow.parquet as pq

parquet_file = pq.ParquetFile("test.parquet")
print(parquet_file.schema_arrow)  # See the embedded schema
print(parquet_file.metadata)      # Row groups, compression, etc.
```

3. **Answer in your notes:**
   - When would you choose CSV over Parquet?
   - When would you choose Parquet over CSV?
   - How does Parquet's row group structure help with filtering?

**Connection to Week 5:**

In Week 5 (Pipelines), you'll read and write Parquet files in your orchestrated workflows. Understanding file formats helps you:
- Choose the right format for each pipeline stage
- Optimize storage and query performance
- Debug issues related to schema mismatches







