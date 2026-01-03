## Week 3 – OLTP vs OLAP, Dimensional Modeling, SCDs

**Goal:** Understand how transactional systems differ from analytical systems, and learn to design dimensional models (facts & dimensions) including slowly changing dimensions.

This week is more **conceptual + design exercises** than pure SQL, although you can sketch tables in PostgreSQL if you like.

### Reference Resources (Free)

- **OLTP vs OLAP basics:**  
  - Short read: [OLTP vs OLAP – Tutorialspoint](https://www.tutorialspoint.com/dwh/dwh_olap_and_oltp.htm).
- **Dimensional modeling / star schemas:**  
  - Article: [Star Schema: The Complete Reference (summary)](https://www.vertabelo.com/blog/data-warehouse-modeling-star-schema/)  
  - Optional deeper dive: find summaries of Kimball’s dimensional modeling techniques.
- **Slowly Changing Dimensions (SCD):**  
  - Overview: [SCD Types 0–6](https://www.datawarehouse4u.info/SCD-Slowly-Changing-Dimensions.html).

---

### Day 1 – OLTP vs OLAP Using Pagila

**Study (15–20 min)**

- Read the OLTP vs OLAP article and skim your Pagila schema to classify tables.

**Exercise**

1. In a markdown note or notebook, answer:
   - Which Pagila tables clearly look **transactional** (OLTP) and why?  
   - Which tables are more **reference / master data**?  
   - If you had to build a reporting layer for executives, why might you not query the OLTP schema directly for heavy analytics?

2. Sketch (on paper or in a markdown file) a **star schema** for analyzing rentals and revenue:
   - Identify at least one **fact table** (e.g., `fact_rental` or `fact_payment`).  
   - Identify dimensions: `dim_customer`, `dim_film`, `dim_store`, `dim_date`, maybe `dim_staff`, `dim_category`.  
   - For each, list key attributes (business keys, natural keys, surrogate keys, measures).

---

### Day 2 – Fact Table Design

**Study (10–15 min)**

- Read the star schema article focusing on **facts vs dimensions** and grain.

**Exercises (design, medium/hard)**

1. **Define the grain** of a rental fact table.  
   - Write a 2–3 sentence description like: “One row per …”.  
   - Decide which measures (columns) belong in `fact_rental` vs should live in dimensions.

2. **Design `fact_payment`**  
   - Columns to include (at minimum): surrogate key, customer key, store key, staff key, date key, amount, payment method, rental key (if applicable).  
   - Think about: should discounts be in the fact? currency? taxes?

3. **Bonus SQL** – Write `CREATE TABLE` statements for `fact_payment` and `dim_customer` as you’ve designed them (even if you don’t populate them yet).

---

### Day 3 – Dimension Design

**Study (10–15 min)**

- Review SCD types from the SCD article.

**Exercises**

1. For each candidate dimension (`customer`, `film`, `store`, `staff`), decide:
   - Is it likely to change slowly, quickly, or almost never?  
   - Which SCD type is appropriate (Type 1, 2, 3, etc.)? Why?

2. **Design `dim_customer` as SCD Type 2 (hard)**  
   - Decide on columns: surrogate key, natural key (customer id), attributes (name, email, address keys, active flag, etc.), `effective_from`, `effective_to`, `is_current`.  
   - Sketch a load process in bullet points: how would you insert new versions when something changes?

3. **Model `dim_film`**  
   - Include film title, rating, length, rental rate, category, etc.  
   - Decide whether rating or rental rate changes would create new SCD rows or be overwritten.

---

### Day 4 – SCD Load Logic (Pseudocode / SQL)

This is a **thinking + pseudocode** day.

**Exercises (hard/challenging)**

1. **Type 1 update logic**  
   - Write **pseudocode or SQL outline** for a daily batch that overwrites changes in a Type 1 dimension (e.g., `dim_store`).  
   - Include steps like staging table, upsert/merge, handling deletes.

2. **Type 2 update logic for `dim_customer` (challenging)**  
   - Assume you have a `stg_customer` staging table with the latest snapshot.  
   - Outline an algorithm (pseudocode or SQL) that:
     - Inserts new customers as new SCD rows.  
     - For existing customers whose attributes changed, closes out old rows (`effective_to` set, `is_current` set to false) and inserts new rows.  
     - Leaves unchanged customers untouched.

3. **Discuss trade‑offs**  
   - In a short note, write pros/cons of Type 1 vs Type 2 in terms of: storage, query complexity, business usefulness.

---

### Day 5 – Applying to a Hypothetical Internal Project

Use this day to **translate what you learned to your actual job context.**

**Exercises (all are important)**

1. Pick **one system** you know well at work (or a realistic proxy) and:
   - Describe its current schema in 5–10 sentences.  
   - Classify it along the OLTP/OLAP spectrum.  
   - Propose a minimal star schema to support executive or product analytics.

2. Identify **two dimensions** and **one fact** from that system that would benefit from SCD Type 2.  
   - Explain what business questions historical tracking would enable (or make easier).

3. Write 3 concrete questions you could ask your current team (data, backend, etc.) that show you understand OLTP vs OLAP and dimensional modeling (e.g., “How are we modeling customer lifecycle events – is it closer to SCD Type 1 or 2?”).







