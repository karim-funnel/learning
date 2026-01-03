## Week 5 – Pipelines, Idempotency, Orchestration, Logging

**Goal:** Build actual robust data pipelines in Python using Polars, understand idempotency, and set up basic orchestration with Airflow.

### Reference Resources (Free)

- **ETL / ELT & pipelines:**
  - Blog: search for a concise overview such as "ETL vs ELT explained for data engineers".
- **Polars:**
  - [Polars User Guide](https://pola-rs.github.io/polars-book/)
  - [Polars API docs](https://pola-rs.github.io/polars/py-polars/html/reference/)
- **Airflow (orchestration):**
  - Docs: [Airflow Concepts](https://airflow.apache.org/docs/apache-airflow/stable/concepts/index.html)
  - [Airflow Tutorial](https://airflow.apache.org/docs/apache-airflow/stable/tutorial/index.html)
- **Logging best practices:**
  - Python docs: [Logging HOWTO](https://docs.python.org/3/howto/logging.html)

### Setup (Do this before Day 1)

**Install dependencies:**

```bash
pip install polars connectorx apache-airflow psycopg2-binary python-dotenv
```

**Create project structure:**

```bash
cd ~/learning
mkdir -p pipelines/{extract,transform,load,logs}
cd pipelines
touch .env
```

**Add to `.env`:**

```bash
PAGILA_DB_URL=postgresql://your_username:your_password@localhost:5432/pagila
```

---

### Day 1 – Extract Pipeline with Polars (Hands-On)

**Study (10 min)**

- Skim Polars getting started guide and read about `read_database`.

**Build an actual extraction script (45–50 min)**

Create `extract/extract_pagila.py`:

```python
import polars as pl
import logging
from datetime import datetime
from pathlib import Path
import os
from dotenv import load_dotenv

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'logs/extract_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

load_dotenv()
DB_URL = os.getenv('PAGILA_DB_URL')

def extract_table(table_name: str, output_dir: Path = Path('data/raw')) -> bool:
    """
    Extract a table from Pagila database and save as Parquet.
    
    Returns True if successful, False otherwise.
    """
    try:
        logger.info(f"Starting extraction for table: {table_name}")
        
        # Create output directory if it doesn't exist
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Extract data using Polars
        query = f"SELECT * FROM {table_name}"
        df = pl.read_database(query, DB_URL)
        
        row_count = len(df)
        logger.info(f"Extracted {row_count} rows from {table_name}")
        
        # Save to parquet with date partition
        date_str = datetime.now().strftime("%Y%m%d")
        output_path = output_dir / f"{table_name}_{date_str}.parquet"
        
        df.write_parquet(output_path)
        logger.info(f"Saved {table_name} to {output_path}")
        
        # Log column info
        logger.info(f"Columns: {df.columns}")
        logger.info(f"Schema: {df.schema}")
        
        return True
        
    except Exception as e:
        logger.error(f"Failed to extract {table_name}: {str(e)}", exc_info=True)
        return False


def extract_all_tables(tables: list[str]) -> dict[str, bool]:
    """Extract multiple tables and return status for each."""
    logger.info(f"Starting batch extraction for {len(tables)} tables")
    start_time = datetime.now()
    
    results = {}
    for table in tables:
        results[table] = extract_table(table)
    
    duration = (datetime.now() - start_time).total_seconds()
    success_count = sum(results.values())
    
    logger.info(f"Extraction complete: {success_count}/{len(tables)} succeeded in {duration:.2f}s")
    
    return results


if __name__ == "__main__":
    tables = ['customer', 'rental', 'payment', 'film', 'inventory', 'store']
    results = extract_all_tables(tables)
    
    # Exit with error code if any extraction failed
    if not all(results.values()):
        logger.error("Some extractions failed")
        exit(1)
    else:
        logger.info("All extractions successful")
        exit(0)
```

**Run it:**

```bash
python extract/extract_pagila.py
```

**Check logs:**

```bash
cat logs/extract_*.log
```

**Homework:**

1. Add incremental extraction: modify `extract_table` to accept a `last_updated` timestamp and only extract newer rows.
2. Add retry logic with exponential backoff for database connection failures.
3. Add a data quality check: validate that extracted row count matches `COUNT(*)` from database.

---

### Day 2 – Transform Pipeline with Polars (Idempotent Design)

**Build an idempotent transformation script (50–60 min)**

Create `transform/transform_customer_metrics.py`:

```python
import polars as pl
import logging
from datetime import datetime, date
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'logs/transform_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def load_latest_extract(table_name: str, data_dir: Path = Path('data/raw')) -> pl.DataFrame:
    """Load the most recent extract for a given table."""
    pattern = f"{table_name}_*.parquet"
    files = sorted(data_dir.glob(pattern))
    
    if not files:
        raise FileNotFoundError(f"No extracts found for {table_name}")
    
    latest = files[-1]
    logger.info(f"Loading {table_name} from {latest}")
    return pl.read_parquet(latest)


def transform_customer_lifetime_value(run_date: date = None) -> pl.DataFrame:
    """
    Transform customer data into lifetime value metrics.
    
    This is designed to be IDEMPOTENT - running it multiple times for the same
    run_date produces the same output.
    """
    if run_date is None:
        run_date = date.today()
    
    logger.info(f"Starting customer LTV transformation for run_date={run_date}")
    
    try:
        # Load raw data
        customers = load_latest_extract('customer')
        payments = load_latest_extract('payment')
        rentals = load_latest_extract('rental')
        
        logger.info(f"Loaded {len(customers)} customers, {len(payments)} payments, {len(rentals)} rentals")
        
        # Transform: compute per-customer metrics
        customer_payments = (
            payments
            .group_by('customer_id')
            .agg([
                pl.count('payment_id').alias('total_payments'),
                pl.sum('amount').alias('total_paid'),
                pl.mean('amount').alias('avg_payment'),
                pl.min('payment_date').alias('first_payment_date'),
                pl.max('payment_date').alias('last_payment_date'),
            ])
        )
        
        customer_rentals = (
            rentals
            .group_by('customer_id')
            .agg([
                pl.count('rental_id').alias('total_rentals'),
                pl.count('return_date').alias('returned_count'),
            ])
            .with_columns([
                (pl.col('returned_count') / pl.col('total_rentals')).alias('return_rate')
            ])
        )
        
        # Join everything together
        result = (
            customers
            .select(['customer_id', 'first_name', 'last_name', 'email', 'store_id', 'active'])
            .join(customer_payments, on='customer_id', how='left')
            .join(customer_rentals, on='customer_id', how='left')
            .with_columns([
                pl.concat_str([pl.col('first_name'), pl.col('last_name')], separator=' ').alias('full_name'),
                pl.lit(run_date).alias('snapshot_date'),  # Idempotency key
            ])
            .with_columns([
                pl.when(pl.col('total_paid') > 150).then(pl.lit('high'))
                  .when(pl.col('total_paid') > 50).then(pl.lit('medium'))
                  .otherwise(pl.lit('low'))
                  .alias('customer_segment')
            ])
            # Fill nulls for customers with no activity
            .with_columns([
                pl.col('total_payments').fill_null(0),
                pl.col('total_paid').fill_null(0),
                pl.col('total_rentals').fill_null(0),
            ])
        )
        
        logger.info(f"Transformation complete: {len(result)} customers processed")
        logger.info(f"Segment distribution:\n{result.group_by('customer_segment').count()}")
        
        return result
        
    except Exception as e:
        logger.error(f"Transformation failed: {str(e)}", exc_info=True)
        raise


def save_transformed_data(df: pl.DataFrame, output_dir: Path = Path('data/transformed')):
    """
    Save transformed data in a way that supports idempotent reruns.
    
    Uses partition by snapshot_date so reruns overwrite the same partition.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    
    snapshot_date = df['snapshot_date'][0]
    output_path = output_dir / f"customer_ltv_{snapshot_date}.parquet"
    
    # Write with overwrite mode for idempotency
    df.write_parquet(output_path)
    logger.info(f"Saved transformed data to {output_path}")


if __name__ == "__main__":
    # Run for today (or pass a specific date for backfills)
    import sys
    
    if len(sys.argv) > 1:
        run_date = date.fromisoformat(sys.argv[1])
    else:
        run_date = date.today()
    
    df = transform_customer_lifetime_value(run_date)
    save_transformed_data(df)
    
    logger.info("Transformation pipeline complete")
```

**Run it:**

```bash
python transform/transform_customer_metrics.py
# Run again - notice it's idempotent (same output)
python transform/transform_customer_metrics.py
# Run for specific date
python transform/transform_customer_metrics.py 2024-01-15
```

**Homework:**

1. Add data quality checks: validate no nulls in key columns, check that total_paid >= 0.
2. Create a second transformation for category performance metrics.
3. Add unit tests using pytest to verify transformation logic on sample data.

---

### Day 3 – Load Pipeline & End-to-End Run

**Build a load script (30 min)**

Create `load/load_to_postgres.py`:

```python
import polars as pl
import logging
from datetime import datetime
from pathlib import Path
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

load_dotenv()
DB_URL = os.getenv('PAGILA_DB_URL')


def load_to_analytics_schema(
    parquet_path: Path,
    table_name: str,
    schema: str = 'analytics'
) -> bool:
    """
    Load transformed data to PostgreSQL analytics schema.
    
    Uses TRUNCATE + INSERT pattern for idempotency.
    """
    try:
        logger.info(f"Loading {parquet_path} to {schema}.{table_name}")
        
        # Read transformed data
        df = pl.read_parquet(parquet_path)
        logger.info(f"Read {len(df)} rows from {parquet_path}")
        
        # Convert to pandas for sqlalchemy compatibility (Polars doesn't support write_database yet)
        pandas_df = df.to_pandas()
        
        # Create engine
        engine = create_engine(DB_URL)
        
        # Write to database (replace mode for idempotency)
        pandas_df.to_sql(
            table_name,
            engine,
            schema=schema,
            if_exists='replace',  # Idempotent: replace entire table
            index=False,
            method='multi',
            chunksize=1000
        )
        
        logger.info(f"Successfully loaded {len(df)} rows to {schema}.{table_name}")
        return True
        
    except Exception as e:
        logger.error(f"Load failed: {str(e)}", exc_info=True)
        return False


if __name__ == "__main__":
    # Find latest transformed file
    transformed_dir = Path('data/transformed')
    latest_file = sorted(transformed_dir.glob('customer_ltv_*.parquet'))[-1]
    
    success = load_to_analytics_schema(latest_file, 'customer_lifetime_value')
    
    if success:
        logger.info("Load complete - verify with: SELECT * FROM analytics.customer_lifetime_value LIMIT 10;")
        exit(0)
    else:
        exit(1)
```

**Test the full pipeline (20 min):**

```bash
# Full end-to-end run
python extract/extract_pagila.py
python transform/transform_customer_metrics.py
python load/load_to_postgres.py

# Verify in psql
psql pagila -c "SELECT customer_segment, COUNT(*), AVG(total_paid) FROM analytics.customer_lifetime_value GROUP BY customer_segment;"
```

**Homework:**

1. Make the load script support incremental loading (append mode with deduplication).
2. Add a manifest table to track pipeline runs (run_id, table_name, row_count, status, timestamp).
3. Wrap the entire ETL in a single script with proper error handling and rollback logic.

---

### Day 4 – Airflow Orchestration (Hands-On)

**Study (15 min)**

- Read Airflow tutorial sections on DAGs, operators, and task dependencies.

**Setup Airflow (one-time, 10 min):**

```bash
# Set airflow home
export AIRFLOW_HOME=~/learning/airflow

# Initialize database
airflow db init

# Create user
airflow users create \
    --username admin \
    --password admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com
```

**Create an Airflow DAG (35 min)**

Create `airflow/dags/pagila_etl_dag.py`:

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from datetime import timedelta
import logging

default_args = {
    'owner': 'data-eng',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'pagila_customer_ltv_pipeline',
    default_args=default_args,
    description='Extract, transform, and load Pagila customer LTV metrics',
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    start_date=days_ago(1),
    catchup=False,
    tags=['pagila', 'analytics'],
)

# Task 1: Extract
extract_task = BashOperator(
    task_id='extract_pagila_tables',
    bash_command='cd ~/learning/pipelines && python extract/extract_pagila.py',
    dag=dag,
)

# Task 2: Transform
transform_task = BashOperator(
    task_id='transform_customer_metrics',
    bash_command='cd ~/learning/pipelines && python transform/transform_customer_metrics.py',
    dag=dag,
)

# Task 3: Load
load_task = BashOperator(
    task_id='load_to_analytics',
    bash_command='cd ~/learning/pipelines && python load/load_to_postgres.py',
    dag=dag,
)

# Task 4: Data quality check (Python function)
def check_data_quality(**context):
    import polars as pl
    from pathlib import Path
    
    # Load latest transformed data
    transformed_dir = Path('~/learning/pipelines/data/transformed').expanduser()
    latest_file = sorted(transformed_dir.glob('customer_ltv_*.parquet'))[-1]
    df = pl.read_parquet(latest_file)
    
    # Run checks
    checks_passed = True
    
    # Check 1: No nulls in customer_id
    null_count = df['customer_id'].null_count()
    if null_count > 0:
        logging.error(f"Found {null_count} null customer_ids")
        checks_passed = False
    
    # Check 2: Total paid should be non-negative
    negative_count = len(df.filter(pl.col('total_paid') < 0))
    if negative_count > 0:
        logging.error(f"Found {negative_count} negative total_paid values")
        checks_passed = False
    
    # Check 3: Minimum row count
    if len(df) < 100:
        logging.error(f"Only {len(df)} customers - expected at least 100")
        checks_passed = False
    
    if checks_passed:
        logging.info("All data quality checks passed")
    else:
        raise ValueError("Data quality checks failed")

quality_check_task = PythonOperator(
    task_id='data_quality_checks',
    python_callable=check_data_quality,
    dag=dag,
)

# Set dependencies
extract_task >> transform_task >> load_task >> quality_check_task
```

**Run Airflow (separate terminal):**

```bash
export AIRFLOW_HOME=~/learning/airflow
airflow scheduler &
airflow webserver --port 8080
```

Visit `http://localhost:8080` and trigger your DAG!

**Homework:**

1. Add SLA monitoring: alert if the DAG takes longer than 30 minutes.
2. Add a separate task for each table extraction (parallel extraction).
3. Add a cleanup task that archives old parquet files after successful load.
4. Create a second DAG for weekly aggregations that depends on daily runs.

---

### Day 5 – Monitoring, Logging, and Failure Recovery

**Exercises (conceptual + practical, 60 min)**

1. **Enhance logging** - Update your scripts to include:
   - Structured logging with JSON format
   - Correlation IDs to track a single run across all steps
   - Performance metrics (duration, rows processed per second)

2. **Create a metrics table** in PostgreSQL:

   ```sql
   CREATE TABLE analytics.pipeline_runs (
       run_id UUID PRIMARY KEY,
       dag_id VARCHAR(100),
       task_id VARCHAR(100),
       run_date DATE,
       status VARCHAR(20),
       rows_processed INT,
       duration_seconds FLOAT,
       error_message TEXT,
       created_at TIMESTAMP DEFAULT NOW()
   );
   ```

   Update your Python scripts to log to this table.

3. **Failure scenario testing:**
   - Simulate a database connection failure - does your pipeline retry correctly?
   - Simulate a data quality failure - does the DAG stop before loading bad data?
   - Run the same DAG twice for the same date - verify idempotency.

4. **Create a monitoring dashboard query:**

   ```sql
   -- Daily pipeline health
   SELECT 
       run_date,
       dag_id,
       COUNT(*) AS total_runs,
       SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) AS successful_runs,
       AVG(duration_seconds) AS avg_duration,
       SUM(rows_processed) AS total_rows
   FROM analytics.pipeline_runs
   WHERE run_date >= CURRENT_DATE - 7
   GROUP BY run_date, dag_id
   ORDER BY run_date DESC;
   ```

5. **Document your pipeline:**
   
   Create `pipelines/README.md` with:
   - Architecture diagram (can be text-based)
   - How to run each component
   - Idempotency guarantees
   - Failure recovery procedures
   - SLA expectations

---

### Wrap-Up

By the end of this week, you should have:

- Built real ETL pipelines using Python + Polars ✓
- Understood and implemented idempotency patterns ✓
- Set up Airflow and created production-like DAGs ✓
- Implemented comprehensive logging and monitoring ✓
- Practiced failure recovery scenarios ✓

**Commit everything to git!** Your pipeline code is now portfolio-ready.
