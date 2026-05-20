"""
## CSV to Snowflake — Raw Ingestion DAG

Full-refresh load of CSV files from GCS into the Snowflake RAW schema.

Schema is inferred natively via INFER_SCHEMA() on each GCS file, so
column types are determined by Snowflake without any manual DDL.

Adding a new table requires only updating 'job_config' in the Airflow UI..

Load tiers (tables within each tier run in parallel):
  Tier 1  Reference tables (no upstream dependencies)
  Tier 2  Entity tables    (depend on tier 1)
  Tier 3  Facts/relations  (depend on tier 2)
  Tier 4  Member relations (depend on tier 3)
"""

from airflow.sdk import dag, task, Asset
from airflow.models import Variable
from airflow.operators.empty import EmptyOperator
from pendulum import datetime

from include.helpers.csv_loader import load_csv_to_snowflake

from include.helpers.slack_notifications import send_slack_success_alert, send_slack_failure_alert


@dag(
    schedule=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    default_args={
        "owner": "data-engineering", 
        "retries": 1,
        "on_failure_callback": send_slack_failure_alert
    },
    on_success_callback=send_slack_success_alert,
    tags=["ingestion", "snowflake", "raw", "gcs"],
    doc_md=__doc__,
)
def csv_to_snowflake_ingestion():

    @task
    def get_tier_tables(tier_key: str) -> list[str]:
        """
        Fetch the list of tables for a given tier from the 'job_config' Variable.
        Args:
            tier_key: Tier identifier key..

        Returns:
            List of table names to load in this tier.
        """
        config = Variable.get("job_config", deserialize_json=True)
        return config["table_tiers"][tier_key]

    @task(map_index_template="{{ table_name_for_ui }}")
    def load_table(table_name: str) -> None:
        """
        Load a single CSV file from GCS into a Snowflake RAW table.       

        Args:
            table_name: CSV filename without .csv; also the Snowflake table name.
        """
        from airflow.operators.python import get_current_context
        context = get_current_context()
        context["table_name_for_ui"] = table_name

        config = Variable.get("job_config", deserialize_json=True)
        load_csv_to_snowflake(table_name, config)

    tier_1_tables = get_tier_tables("tier_1")
    tier_2_tables = get_tier_tables("tier_2")
    tier_3_tables = get_tier_tables("tier_3")
    tier_4_tables = get_tier_tables("tier_4")

    # Expand tasks dynamically 
    t1 = load_table.expand(table_name=tier_1_tables)
    t2 = load_table.expand(table_name=tier_2_tables)
    t3 = load_table.expand(table_name=tier_3_tables)
    t4 = load_table.expand(table_name=tier_4_tables)

    # Define asset for downstream dbt transformations
    raw_asset = Asset("snowflake://raw/meetup")
    
    emit_dataset = EmptyOperator(
        task_id="emit_raw_dataset",
        outlets=[raw_asset],
    )

    # Enforce tier-level ordering
    tier_1_tables >> t1 >> tier_2_tables >> t2 >> tier_3_tables >> t3 >> tier_4_tables >> t4 >> emit_dataset


csv_to_snowflake_ingestion()
