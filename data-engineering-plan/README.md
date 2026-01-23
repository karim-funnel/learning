## Data Engineering Foundations Plan (Enhanced)

You created this plan to build **great foundations in data work** and to be able to lead more data‑intensive projects internally.  
You'll study **45–60 minutes per day**, focusing on Zach Wilson's core concepts:

- **ANSI SQL** ✓
- **Distributed compute** ✓
- **OLTP vs OLAP** ✓
- **CAP theorem** ✓
- **Slowly‑changing dimensional modeling (SCD)** ✓
- **Fact data modeling** ✓
- **Logging best practices** ✓
- **AVRO / Thrift schemas** ✓
- **Idempotent pipelines** ✓
- **Job orchestration** ✓
- **Flexible schema vs defined schema** ✓
- **Data quality testing** ✓

You already know Python and basic SQL; this plan leans heavily on **PostgreSQL + the Pagila sample database** that's already in your repo.

### 🎯 Key Improvements (v2.0)

This enhanced version addresses the original plan's weaknesses:

1. **Added Week 2.5 for dbt** - Hands-on transformation layer with modern tooling
2. **Added Week 4.5 for Substrait** - Query plan interoperability (SQL → relational plans)
2. **Python/Polars integration** - Actual pipeline code instead of pseudocode (Week 5)
3. **Hands-on tool setup** - Great Expectations, Airflow, dbt all installed and used
4. **Version control throughout** - Git best practices integrated from Day 1
5. **Portfolio-ready outputs** - Each week produces work you can show your manager

### High‑Level Roadmap (10 Weeks)

- **Weeks 1–2 – Deep ANSI SQL with Pagila**

  - Goal: Go from "basic SQL" to "can express almost any analytical question in SQL".
  - Focus: joins, `GROUP BY` + `HAVING`, subqueries, CTEs, window functions.
  - Files: `week01-sql-joins-aggregations.md`, `week02-sql-analytics-window-functions.md`.
  - **Git practice:** Commit homework daily.

- **Week 2.5 – dbt: Transformations & Testing** ⭐ NEW

  - Goal: Get hands-on with the de-facto standard for analytics transformations.
  - Focus: Staging models, marts, tests, documentation, lineage.
  - File: `week02.5-dbt-transformations.md`.
  - **Deliverable:** Working dbt project with tests and docs.

- **Week 3 – OLTP vs OLAP, dimensional modeling, SCDs**

  - Goal: Understand how data warehouses are modeled and how SCDs work.
  - Files: `week03-data-modeling-and-scds.md`.
  - **Deliverable:** Star schema design for your domain.

- **Week 4 – Distributed compute, CAP theorem, schemas**

  - Goal: Conceptual foundations for distributed systems used in data engineering.
  - Topics: Distributed compute (Spark/Beam examples), CAP, AVRO/Thrift, flexible vs defined schemas.
  - Files: `week04-distributed-compute-and-schemas.md`.
  - **Deliverable:** Avro schema designs for events.

- **Week 4.5 – Substrait: Relational Plans & Interoperable Compute** ⭐ NEW

  - Goal: Go from “what is Substrait” → upper beginner / early intermediate: read/understand/validate Substrait plans and relate them to SQL semantics.
  - Focus: relational operators, expressions/types, serialization, validator + tutorial workflow.
  - File: `week04.5-substrait.md`.
  - **Deliverable:** A short write-up + annotated plan examples you can share internally.

- **Week 5 – Pipelines, Idempotency, Orchestration, Logging** ⭐ ENHANCED

  - Goal: Build actual robust data pipelines using Python + Polars.
  - Focus: Extract, transform, load scripts with idempotent design, Airflow DAGs.
  - File: `week05-pipelines-orchestration-logging.md`.
  - **Deliverable:** Working ETL pipeline orchestrated by Airflow.

- **Week 6 – Data Quality and Testing** ⭐ ENHANCED

  - Goal: Set up Great Expectations and integrate quality checks into pipelines.
  - Focus: Expectation suites, checkpoints, monitoring, alerting.
  - File: `week06-data-quality-testing.md`.
  - **Deliverable:** Automated data quality framework with SLAs.

- **Weeks 7–8 – Capstone: design a small data platform**
  - Goal: Pull everything together into an end‑to‑end design you could defend in an interview or internal review.
  - File: `week07-08-capstone-project.md`.
  - **Deliverable:** Complete data platform design document + implementation.

### 📚 Supporting Materials

- **Version Control Guide** ⭐ NEW
  - File: `version-control-guide.md`
  - Covers: Git setup, daily workflow, commit strategies, GitHub integration
  - **Start here:** Set up git before Week 1 Day 1!

### What You'll Build

By the end of this plan, you'll have:

1. **SQL Expertise:** Complex queries with window functions, CTEs, and analytics patterns
2. **dbt Project:** Staging → marts transformation layer with tests
3. **Python Pipelines:** Extract, transform, load scripts using Polars
4. **Airflow DAGs:** Production-ready orchestration with retries and monitoring
5. **Data Quality Framework:** Automated testing with Great Expectations
6. **Star Schema Design:** Dimensional models with SCD implementation
7. **Git Repository:** Version-controlled portfolio of all your work
8. **Capstone Project:** End-to-end data platform design

### Tools You'll Master

**Core Stack (all free/open-source):**

- PostgreSQL (database)
- Python 3.x + Polars (data processing)
- dbt Core (transformations)
- Apache Airflow (orchestration)
- Great Expectations (data quality)
- Git/GitHub (version control)
- Pagila sample database (practice data)

**Python Libraries:**

- `polars` - Fast DataFrame library (better than pandas for data engineering)
- `connectorx` - High-performance database connections
- `sqlalchemy` - Database abstraction layer
- `great_expectations` - Data quality validation
- `apache-airflow` - Workflow orchestration

### Daily Workflow

Each day (45-60 minutes):

1. **Check your git status** - Start where you left off
2. **Study** (10-15 min) - Read docs/articles from the week file
3. **Practice** (30-45 min) - Complete exercises and homework
4. **Commit your work** - Document your progress with git
5. **Optional:** Push to GitHub for backup

### Pacing Guidance

- **Standard pace:** Follow the plan as written (9 weeks total)
- **Slower pace:** Take 2 days per "day" of work (18 weeks total)
- **Faster pace:** Skip warm-ups, focus on hard challenges (7-8 weeks)

**Don't skip Week 2.5, 5, or 6** - These are the most practical and portfolio-relevant!

### Getting Started Checklist

Before Week 1 Day 1:

- [ ] Install PostgreSQL and load Pagila database
- [ ] Install Python packages: `pip install polars dbt-core dbt-postgres`
- [ ] Set up git repository (see `version-control-guide.md`)
- [ ] Create folder structure: `answers/week01/day01/`
- [ ] Test database connection: `psql pagila`

### How This Connects to Your Job

- **Weeks 1-2:** SQL skills transfer immediately to analytical work
- **Week 2.5:** dbt is increasingly standard for analytics teams
- **Week 3:** Design skills for data modeling discussions
- **Weeks 5-6:** Direct application to building data pipelines internally
- **Weeks 7-8:** Proposal-ready design for leading data projects

### Questions or Stuck?

**If a week feels too hard:**

- Slow down, take 2 days per "day"
- Review the prerequisite weeks
- Focus on easier homework, skip the "challenging" ones initially

**If a week feels too easy:**

- Do all the challenges
- Add your own exercises
- Jump ahead to the capstone

**If you want to apply this to work immediately:**

- Prioritize Weeks 2.5, 5, and 6 (most practical)
- Use your actual work data instead of Pagila (with permission!)
- Share your learnings with your team as you go

### Success Metrics

You'll know you've achieved "great foundations" when you can:

✓ Write complex SQL queries without Googling basic syntax  
✓ Design a star schema for a new business domain  
✓ Build an idempotent data pipeline with quality checks  
✓ Explain CAP theorem trade-offs in your systems  
✓ Implement SCD Type 2 from scratch  
✓ Debug data quality issues systematically  
✓ Propose data architecture improvements to your team  
✓ Lead a data-intensive project internally with confidence

**You've got this! Start with `version-control-guide.md`, then dive into Week 1. See you on the other side! 🚀**
