"""
Reusable functions for exporting Snowflake tables to GCS as Parquet files.

Snowflake writes files directly into GCS via external stage.
The Airflow worker only sends SQL — no data passes through Python.
"""

from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook


def _get_hook(job_config: dict) -> SnowflakeHook:
    """
    Build Snowflake hook from Airflow connection and runtime config.
    """
    return SnowflakeHook(
        snowflake_conn_id=job_config["conn_id"],
        database=job_config["database"],
        schema=job_config["schema"],
        role=job_config["role"],
    )


def _export_gcs_path(job_config: dict, table_name: str) -> str:
    """
    Build export destination path inside GCS stage.

    Example:
      @RAW.gcs_stage/meetup-staging/categories/
    """
    return (
        f"@{job_config['stage_name']}"
        f"/meetup-staging"
        f"/{table_name}/"
    )


def export_table_to_gcs(
    hook: SnowflakeHook,
    job_config: dict,
    table_name: str,
) -> None:
    """
    Export Snowflake table into GCS as Parquet files.

    Args:
        hook: SnowflakeHook instance.
        job_config: Runtime config dictionary.
        table_name: Snowflake table name.
    """

    export_path = _export_gcs_path(job_config, table_name)

    sql = f"""
    COPY INTO '{export_path}'
    FROM (
        SELECT *
        FROM {table_name}
    )
    FILE_FORMAT = (
        TYPE = CSV
    )
    OVERWRITE = TRUE
    HEADER = TRUE
    MAX_FILE_SIZE = 50000000;
    """

    hook.run(sql)


def unload_snowflake_table_to_gcs(
    table_name: str,
    job_config: dict,
) -> None:
    """
    Export a Snowflake table into GCS.

    Flow:
      1. Read Snowflake table
      2. Write Parquet files directly to GCS

    Args:
        table_name: Snowflake table name.
        job_config: Config dictionary from Airflow Variable.
    """

    hook = _get_hook(job_config)

    export_table_to_gcs(
        hook=hook,
        job_config=job_config,
        table_name=table_name,
    )