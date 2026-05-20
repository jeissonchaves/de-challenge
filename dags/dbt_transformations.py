from pathlib import Path
from pendulum import datetime
from airflow.sdk import dag, Asset
from airflow.operators.empty import EmptyOperator
from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping


DBT_PROJECT_PATH = Path("/usr/local/airflow/dbt")


profile_config = ProfileConfig(
    profile_name="meetup_profile",
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id="snowflake_default",
        profile_args={"schema": "STAGING"},
    ),
)
from include.helpers.slack_notifications import send_slack_success_alert, send_slack_failure_alert

@dag(
    # Trigger this DAG automatically when the ingestion DAG emits this Asset
    schedule=[Asset("snowflake://raw/meetup")],
    start_date=datetime(2025, 1, 1),
    catchup=False,
    default_args={
        "owner": "data-engineering", 
        "retries": 1,
        "on_failure_callback": send_slack_failure_alert
    },
    on_success_callback=send_slack_success_alert,
    tags=["transformation", "dbt", "snowflake", "staging"],
)
def dbt_transformations():
    
    # Cosmos automatically parses the dbt project and creates an Airflow task for each model
    run_dbt_models = DbtTaskGroup(
        group_id="run_dbt_models",
        project_config=ProjectConfig(DBT_PROJECT_PATH),
        profile_config=profile_config,
    )

    # Define asset for downstream dbt transformations
    stg_asset = Asset("snowflake://stg/meetup")
    
    emit_dataset = EmptyOperator(
        task_id="emit_stg_dataset",
        outlets=[stg_asset],
    )
    run_dbt_models >> emit_dataset

dbt_transformations()
