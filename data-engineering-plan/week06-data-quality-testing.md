## Week 6 – Data Quality and Testing (Hands-On)

**Goal:** Set up Great Expectations to automatically test data quality on your Pagila pipelines, and integrate tests into your Airflow DAGs.

### Reference Resources (Free)

- **Great Expectations:**
  - [Getting Started guide](https://docs.greatexpectations.io/docs/tutorials/)
  - [Core Concepts](https://docs.greatexpectations.io/docs/terms/expectation)
- **dbt tests (for comparison):**
  - [dbt Testing docs](https://docs.getdbt.com/docs/build/tests)

### Setup (Do this before Day 1)

**Install Great Expectations:**

```bash
pip install great_expectations
```

---

### Day 1 – Great Expectations Setup & First Expectations

**Setup (20 min)**

```bash
cd ~/learning/pipelines
great_expectations init
```

Follow the prompts - it will create a `great_expectations/` directory.

**Connect to your data source:**

```bash
great_expectations datasource new
```

Choose:
1. "Files on a filesystem" → point to `data/transformed/`
2. OR "Relational database" → connect to Pagila PostgreSQL

**Create your first Expectation Suite (40 min)**

Let's create expectations for the customer LTV data:

```bash
great_expectations suite new
```

Choose:
- Suite name: `customer_ltv_suite`
- Data source: your transformed parquet files or postgres analytics schema
- Sample: customer_lifetime_value table/file

This opens a Jupyter notebook. Add these expectations:

```python
# In the Jupyter notebook that opens:

# 1. Column existence
validator.expect_table_columns_to_match_ordered_list(
    column_list=['customer_id', 'full_name', 'email', 'store_id', 'active', 
                 'total_payments', 'total_paid', 'avg_payment', 'first_payment_date',
                 'last_payment_date', 'snapshot_date', 'customer_segment', 'total_rentals']
)

# 2. No nulls in key columns
validator.expect_column_values_to_not_be_null('customer_id')
validator.expect_column_values_to_not_be_null('full_name')
validator.expect_column_values_to_not_be_null('email')

# 3. Unique customer IDs
validator.expect_column_values_to_be_unique('customer_id')

# 4. Valid value ranges
validator.expect_column_values_to_be_between(
    'total_paid',
    min_value=0,
    max_value=500  # Reasonable max for DVD rentals
)

validator.expect_column_values_to_be_between(
    'total_rentals',
    min_value=0,
    max_value=100
)

# 5. Valid categorical values
validator.expect_column_values_to_be_in_set(
    'customer_segment',
    value_set=['low', 'medium', 'high']
)

validator.expect_column_values_to_be_in_set(
    'active',
    value_set=[True, False, 1, 0]
)

# 6. Email format validation
validator.expect_column_values_to_match_regex(
    'email',
    regex=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
)

# 7. Relationship checks
validator.expect_column_max_to_be_between(
    'avg_payment',
    min_value=0,
    max_value=20  # Reasonable max for single payment
)

# 8. Row count expectations
validator.expect_table_row_count_to_be_between(
    min_value=100,  # At least 100 customers
    max_value=1000  # Not more than 1000 (sanity check)
)

# Save the suite
validator.save_expectation_suite(discard_failed_expectations=False)
```

**Run your first checkpoint:**

```bash
great_expectations checkpoint new customer_ltv_checkpoint
```

This creates a checkpoint config. Run it:

```bash
great_expectations checkpoint run customer_ltv_checkpoint
```

Check the Data Docs:

```bash
great_expectations docs build
```

Open the generated HTML to see your validation results!

---

### Day 2 – Custom Expectations & Advanced Validation

**Create a Python script for programmatic testing (50 min)**

Create `data_quality/validate_customer_ltv.py`:

```python
import great_expectations as gx
from great_expectations.checkpoint import SimpleCheckpoint
from pathlib import Path
import logging
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def validate_customer_ltv_data(data_path: Path) -> bool:
    """
    Run Great Expectations validation on customer LTV data.
    
    Returns True if all expectations pass, False otherwise.
    """
    try:
        logger.info(f"Starting validation for {data_path}")
        
        # Initialize GX context
        context = gx.get_context()
        
        # Create a validator for the data
        validator = context.sources.pandas_default.read_parquet(str(data_path))
        
        # Add expectations programmatically
        validator.expect_column_values_to_not_be_null('customer_id')
        validator.expect_column_values_to_be_unique('customer_id')
        validator.expect_column_values_to_be_between('total_paid', min_value=0)
        validator.expect_column_values_to_be_in_set(
            'customer_segment', 
            value_set=['low', 'medium', 'high']
        )
        
        # Custom expectation: high-value customers should have many rentals
        def custom_high_value_check(validator):
            # Get the dataframe
            df = validator.execution_engine.batch_manager.active_batch.data.dataframe
            
            # Check: customers with segment='high' should have total_paid > 150
            high_segment = df[df['customer_segment'] == 'high']
            invalid_high = high_segment[high_segment['total_paid'] <= 150]
            
            if len(invalid_high) > 0:
                logger.warning(f"Found {len(invalid_high)} high-segment customers with total_paid <= 150")
                return False
            return True
        
        # Run validation
        results = validator.validate()
        
        # Check results
        if results['success']:
            logger.info("✓ All expectations passed")
            return True
        else:
            logger.error("✗ Some expectations failed")
            for result in results['results']:
                if not result['success']:
                    logger.error(f"  Failed: {result['expectation_config']['expectation_type']}")
            return False
            
    except Exception as e:
        logger.error(f"Validation failed with error: {str(e)}", exc_info=True)
        return False


def validate_with_checkpoint(checkpoint_name: str = 'customer_ltv_checkpoint') -> bool:
    """
    Run validation using a pre-configured checkpoint.
    """
    try:
        logger.info(f"Running checkpoint: {checkpoint_name}")
        
        context = gx.get_context()
        
        checkpoint = context.get_checkpoint(checkpoint_name)
        result = checkpoint.run()
        
        if result['success']:
            logger.info("✓ Checkpoint passed")
            return True
        else:
            logger.error("✗ Checkpoint failed")
            return False
            
    except Exception as e:
        logger.error(f"Checkpoint execution failed: {str(e)}", exc_info=True)
        return False


if __name__ == "__main__":
    import sys
    
    # Find latest transformed file
    transformed_dir = Path('data/transformed')
    latest_file = sorted(transformed_dir.glob('customer_ltv_*.parquet'))[-1]
    
    logger.info(f"Validating {latest_file}")
    
    # Method 1: Programmatic validation
    success = validate_customer_ltv_data(latest_file)
    
    # Method 2: Using checkpoint (uncomment to use)
    # success = validate_with_checkpoint('customer_ltv_checkpoint')
    
    if success:
        logger.info("Data quality validation passed")
        exit(0)
    else:
        logger.error("Data quality validation failed")
        exit(1)
```

**Run it:**

```bash
cd ~/learning/pipelines
python data_quality/validate_customer_ltv.py
```

**Homework:**

1. Create a suite for the raw extracted data (payment, rental, customer tables).
2. Add expectations to check for data drift (e.g., mean payment amount shouldn't change by >20% day-over-day).
3. Create a custom expectation that validates referential integrity (all customer_ids in payments exist in customers).

---

### Day 3 – Integrate Quality Checks into Airflow

**Update your Airflow DAG (50 min)**

Modify `airflow/dags/pagila_etl_dag.py` to include GX validation:

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from datetime import timedelta
import logging

# ... (keep existing imports and default_args)

dag = DAG(
    'pagila_customer_ltv_pipeline_with_quality',
    default_args=default_args,
    description='ETL pipeline with integrated data quality checks',
    schedule_interval='0 2 * * *',
    start_date=days_ago(1),
    catchup=False,
    tags=['pagila', 'analytics', 'data-quality'],
)

# Existing tasks
extract_task = BashOperator(
    task_id='extract_pagila_tables',
    bash_command='cd ~/learning/pipelines && python extract/extract_pagila.py',
    dag=dag,
)

# NEW: Validate raw data after extraction
def validate_raw_data(**context):
    """Validate raw extracted data before transformation."""
    import great_expectations as gx
    from pathlib import Path
    
    context_gx = gx.get_context()
    
    # Validate each extracted table
    tables = ['customer', 'rental', 'payment']
    all_passed = True
    
    for table in tables:
        data_dir = Path('~/learning/pipelines/data/raw').expanduser()
        latest_file = sorted(data_dir.glob(f'{table}_*.parquet'))[-1]
        
        logging.info(f"Validating raw {table} data: {latest_file}")
        
        # Simple validation: check row count and no completely null columns
        validator = context_gx.sources.pandas_default.read_parquet(str(latest_file))
        validator.expect_table_row_count_to_be_between(min_value=1)
        
        results = validator.validate()
        if not results['success']:
            logging.error(f"Raw data validation failed for {table}")
            all_passed = False
    
    if not all_passed:
        raise ValueError("Raw data validation failed")
    
    logging.info("All raw data validations passed")

validate_raw_task = PythonOperator(
    task_id='validate_raw_data',
    python_callable=validate_raw_data,
    dag=dag,
)

transform_task = BashOperator(
    task_id='transform_customer_metrics',
    bash_command='cd ~/learning/pipelines && python transform/transform_customer_metrics.py',
    dag=dag,
)

# NEW: Validate transformed data before loading
validate_transformed_task = BashOperator(
    task_id='validate_transformed_data',
    bash_command='cd ~/learning/pipelines && python data_quality/validate_customer_ltv.py',
    dag=dag,
)

load_task = BashOperator(
    task_id='load_to_analytics',
    bash_command='cd ~/learning/pipelines && python load/load_to_postgres.py',
    dag=dag,
)

# NEW: Post-load validation (validate data in database)
def validate_loaded_data(**context):
    """Validate data in the analytics schema after loading."""
    import polars as pl
    import os
    from dotenv import load_dotenv
    
    load_dotenv()
    DB_URL = os.getenv('PAGILA_DB_URL')
    
    # Query the loaded table
    query = "SELECT * FROM analytics.customer_lifetime_value"
    df = pl.read_database(query, DB_URL)
    
    # Basic checks
    assert len(df) > 0, "No data loaded"
    assert df['customer_id'].null_count() == 0, "Null customer IDs found"
    assert df['total_paid'].min() >= 0, "Negative payment amounts found"
    
    logging.info(f"✓ Post-load validation passed: {len(df)} rows in analytics table")

post_load_validation_task = PythonOperator(
    task_id='post_load_validation',
    python_callable=validate_loaded_data,
    dag=dag,
)

# Updated dependency chain with quality gates
extract_task >> validate_raw_task >> transform_task >> validate_transformed_task >> load_task >> post_load_validation_task
```

**Key improvements:**
- **Validate raw data** after extraction (catches upstream issues early)
- **Validate transformed data** before loading (prevents bad data from entering warehouse)
- **Validate loaded data** in the database (ensures load process didn't corrupt data)
- Each validation is a **quality gate** - pipeline stops if checks fail

**Test your enhanced DAG:**

```bash
# Restart Airflow to pick up changes
airflow dags list | grep pagila
airflow dags trigger pagila_customer_ltv_pipeline_with_quality
```

**Homework:**

1. Add email/Slack notifications when quality checks fail.
2. Create a separate "data quality" DAG that runs hourly to monitor data drift.
3. Add an Airflow sensor that waits for data freshness before running quality checks.

---

### Day 4 – Monitoring & Alerting for Data Quality

**Create a data quality metrics table (30 min)**

```sql
-- Run in psql pagila
CREATE TABLE IF NOT EXISTS analytics.data_quality_results (
    check_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    run_date DATE NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    expectation_type VARCHAR(200) NOT NULL,
    success BOOLEAN NOT NULL,
    observed_value TEXT,
    expected_value TEXT,
    row_count INT,
    failed_row_count INT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_dq_results_date ON analytics.data_quality_results(run_date DESC);
CREATE INDEX idx_dq_results_table ON analytics.data_quality_results(table_name);
```

**Create a script to log GX results to database (30 min)**

Create `data_quality/log_results.py`:

```python
import great_expectations as gx
from sqlalchemy import create_engine
import pandas as pd
from datetime import date
import logging
import os
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.getenv('PAGILA_DB_URL')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def log_validation_results_to_db(checkpoint_name: str, run_date: date = None):
    """Run checkpoint and log results to PostgreSQL."""
    if run_date is None:
        run_date = date.today()
    
    try:
        # Run checkpoint
        context = gx.get_context()
        checkpoint = context.get_checkpoint(checkpoint_name)
        result = checkpoint.run()
        
        # Parse results
        results_list = []
        for validation in result.run_results.values():
            for expectation_result in validation['validation_result']['results']:
                results_list.append({
                    'run_date': run_date,
                    'table_name': 'customer_lifetime_value',  # or extract from context
                    'expectation_type': expectation_result['expectation_config']['expectation_type'],
                    'success': expectation_result['success'],
                    'observed_value': str(expectation_result.get('result', {}).get('observed_value')),
                    'expected_value': str(expectation_result.get('result', {}).get('expected_value')),
                    'row_count': expectation_result.get('result', {}).get('element_count', 0),
                    'failed_row_count': expectation_result.get('result', {}).get('unexpected_count', 0),
                })
        
        # Load to database
        if results_list:
            df = pd.DataFrame(results_list)
            engine = create_engine(DB_URL)
            df.to_sql(
                'data_quality_results',
                engine,
                schema='analytics',
                if_exists='append',
                index=False
            )
            logger.info(f"Logged {len(results_list)} quality check results to database")
        
        return result['success']
        
    except Exception as e:
        logger.error(f"Failed to log results: {str(e)}", exc_info=True)
        return False


if __name__ == "__main__":
    success = log_validation_results_to_db('customer_ltv_checkpoint')
    exit(0 if success else 1)
```

**Create a monitoring query:**

```sql
-- Daily data quality dashboard
WITH daily_summary AS (
    SELECT 
        run_date,
        table_name,
        COUNT(*) AS total_checks,
        SUM(CASE WHEN success THEN 1 ELSE 0 END) AS passed_checks,
        SUM(CASE WHEN NOT success THEN 1 ELSE 0 END) AS failed_checks,
        ROUND(100.0 * SUM(CASE WHEN success THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_rate
    FROM analytics.data_quality_results
    WHERE run_date >= CURRENT_DATE - 7
    GROUP BY run_date, table_name
)
SELECT * FROM daily_summary
ORDER BY run_date DESC, success_rate ASC;

-- Failed checks detail
SELECT 
    run_date,
    table_name,
    expectation_type,
    observed_value,
    expected_value,
    failed_row_count
FROM analytics.data_quality_results
WHERE NOT success
    AND run_date >= CURRENT_DATE - 7
ORDER BY run_date DESC;
```

---

### Day 5 – Real-World Application & Best Practices

**Exercises (60 min total)**

**1. Define a Data Quality SLA (15 min)**

Create `data_quality/SLA.md`:

```markdown
# Data Quality SLA - Pagila Analytics

## Critical Checks (Pipeline fails if these fail)

- **customer_lifetime_value table:**
  - No null customer_ids
  - No duplicate customer_ids
  - All total_paid values >= 0
  - Row count between 100-1000
  - Success rate: 100% required

## Warning Checks (Pipeline succeeds but alerts sent)

- **customer_lifetime_value table:**
  - < 5% customers with invalid email formats
  - Average payment within ±20% of historical average
  - Success rate: 95% required

## Monitoring Checks (Informational only)

- Distribution of customer segments (track drift)
- Data freshness (snapshot_date = today)
- Success rate: 80% required

## Alert Channels

- **Critical failures:** Page on-call engineer, stop pipeline
- **Warning failures:** Slack #data-quality channel
- **Monitoring issues:** Daily email digest
```

**2. Implement tiered alerting (20 min)**

Create `data_quality/alert_manager.py`:

```python
import logging
from enum import Enum

class AlertLevel(Enum):
    CRITICAL = "critical"
    WARNING = "warning"
    INFO = "info"

class DataQualityAlertManager:
    """Manages alerts based on data quality check results."""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def send_alert(self, level: AlertLevel, message: str, details: dict = None):
        """Send alert based on severity level."""
        if level == AlertLevel.CRITICAL:
            self._critical_alert(message, details)
        elif level == AlertLevel.WARNING:
            self._warning_alert(message, details)
        else:
            self._info_alert(message, details)
    
    def _critical_alert(self, message: str, details: dict):
        """Critical alerts stop the pipeline."""
        self.logger.error(f"CRITICAL: {message}")
        if details:
            self.logger.error(f"Details: {details}")
        # In production: send to PagerDuty, page on-call, etc.
        raise ValueError(f"Critical data quality issue: {message}")
    
    def _warning_alert(self, message: str, details: dict):
        """Warning alerts notify but don't stop pipeline."""
        self.logger.warning(f"WARNING: {message}")
        if details:
            self.logger.warning(f"Details: {details}")
        # In production: send to Slack, create Jira ticket, etc.
    
    def _info_alert(self, message: str, details: dict):
        """Informational alerts are logged only."""
        self.logger.info(f"INFO: {message}")
        if details:
            self.logger.info(f"Details: {details}")

# Example usage
if __name__ == "__main__":
    manager = DataQualityAlertManager()
    
    # Simulate different alert levels
    manager.send_alert(AlertLevel.INFO, "Data quality check completed", 
                      {"checks_run": 10, "passed": 10})
    manager.send_alert(AlertLevel.WARNING, "Email format validation at 92% success",
                      {"expected": 0.95, "actual": 0.92})
    # manager.send_alert(AlertLevel.CRITICAL, "Null customer IDs detected",
    #                   {"null_count": 5})  # This would raise an exception
```

**3. Apply to your job (25 min)**

Answer these questions in a document:

1. **Choose one critical table/dataset at work:**
   - What are 5 critical quality checks it needs?
   - What are 3 warning-level checks?
   - What SLA would you propose (% success required)?

2. **Cost-benefit analysis:**
   - Estimate time to implement automated quality checks for that table
   - Estimate $ cost of a data quality incident (bad data reaching production)
   - Make the business case for data quality automation

3. **Implementation plan:**
   - How would you roll out data quality checks to your team?
   - What tools would you use (Great Expectations, dbt tests, custom scripts)?
   - How would you get buy-in from stakeholders?

4. **Create a sample proposal email** to your manager suggesting this implementation.

---

### Wrap-Up

By the end of this week, you should have:

- Set up Great Expectations on real data ✓
- Created comprehensive expectation suites ✓
- Integrated quality checks into Airflow pipelines ✓
- Built monitoring and alerting infrastructure ✓
- Defined SLAs and alert tiers ✓
- Practiced applying these concepts to your actual job ✓

**This is portfolio-ready work** - you now have a complete data quality framework that most data teams don't have!

**Commit everything to git!**
