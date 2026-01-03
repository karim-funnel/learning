## Weeks 7–8 – Capstone: Design a Small Data Platform

**Goal:** Integrate SQL, modeling, distributed concepts, pipelines, and data quality into a coherent small “data platform” design you could explain in an interview or internal review.

You can base this on:

- The **Pagila** domain (DVD rentals), or  
- A domain closer to your job (recommended).

---

### Step 1 – Choose a Domain and Use Cases

**Deliverables**

1. A 1–2 page write‑up describing:
   - The business domain.  
   - 5–10 key analytics or reporting questions you want to support.  
   - Data sources (OLTP DBs, logs, CSVs, APIs, events).

---

### Step 2 – Model the Warehouse

**Deliverables**

1. A diagram (can be text or a drawing) of:
   - Fact tables (with grain and measures).  
   - Dimension tables (with SCD types).  
2. A short note explaining how OLTP schemas feed into this OLAP model.

Optional: `CREATE TABLE` DDL for a subset of facts/dims in PostgreSQL.

---

### Step 3 – Define Pipelines and Orchestration

**Deliverables**

1. A high‑level diagram of your daily (or hourly) pipelines:
   - Extract, staging, transform, quality checks, publish.  
2. A pseudo‑Airflow (or Prefect) DAG description showing tasks, dependencies, retries, SLAs, and where data quality tests run.
3. An explanation of how you design pipelines to be **idempotent** and **observable** (logs + metrics).

---

### Step 4 – Distributed Compute & Storage Choices

**Deliverables**

1. For your largest/most complex pipeline, describe:
   - Whether you’d use a distributed engine (Spark/Beam/BigQuery/etc.) and why.  
   - How CAP trade‑offs influence your choice of stores (e.g., OLTP DB, warehouse, log store).
2. A short justification of serialization or schema formats (e.g., Avro for events, Parquet for warehouse tables) and schema evolution strategy.

---

### Step 5 – Data Quality & Testing Strategy

**Deliverables**

1. A list of 10–20 concrete data quality tests across your facts and dims.  
2. A plan for running them (where in the DAG, how often, what happens on failure).

---

### Step 6 – Executive‑Level Summary

In 1–2 pages, write an **executive‑friendly overview**:

- What the platform enables.  
- How data flows from source to final dashboards.  
- Why it is reliable, scalable, and trustworthy.  
- What trade‑offs you made (CAP, schema design, latency vs cost).

This document is what you’d actually present if you wanted to lead a new data‑intensive project internally.







