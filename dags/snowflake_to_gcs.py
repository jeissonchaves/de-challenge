"""
## Snowflake to GCS — Reverse ETL / Export DAG

Exports processed Snowflake staging/marts tables back into GCS.
Snowflake writes directly to GCS via the external stage.

Schedule  : None (Manual/Triggered)
Config    : The list of tables is read from the Airflow Variable 'reverse_tables'.
            All Snowflake connection settings are read from 'job_config'.
"""

from airflow.sdk import dag, task, Asset
from airflow.models import Variable
from pendulum import datetime
from include.helpers.snowflake_reverse import unload_snowflake_table_to_gcs
from include.helpers.slack_notifications import send_slack_success_alert, send_slack_failure_alert

@dag(
    schedule=[Asset("snowflake://stg/meetup")],
    start_date=datetime(2025, 1, 1),
    catchup=False,
    default_args={
        "owner": "data-engineering",
        "retries": 1,
        "on_failure_callback": send_slack_failure_alert
    },
    on_success_callback=send_slack_success_alert,
    tags=["export", "snowflake", "staging", "gcs"],
    doc_md=__doc__,
)
def snowflake_to_gcs():

    @task
    def get_tables_to_export() -> list[str]:
        """
        Fetch the list of tables to export from the 'reverse_tables' Variable.
        """
        return Variable.get("reverse_tables", deserialize_json=True)

    @task(map_index_template="{{ table_name_for_ui }}")
    def export_table(table_name: str) -> None:
        """
        Export a single Snowflake STAGING table to GCS as Parquet files.
        """
        from airflow.operators.python import get_current_context
        context = get_current_context()
        context["table_name_for_ui"] = table_name

        config = Variable.get("job_config", deserialize_json=True)        
        
        unload_snowflake_table_to_gcs(table_name, config)

    tables = get_tables_to_export()
    export_table.expand(table_name=tables)

snowflake_to_gcs()
