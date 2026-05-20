"""
Reusable functions for loading CSV files from GCS into Snowflake RAW layer.
All config is read from the Airflow Variable 'job_config'.
"""

from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook


def _get_hook(job_config: dict) -> SnowflakeHook:
    """
    Build a SnowflakeHook using credentials from the Airflow connection
    and runtime config (database, schema, role) from job_config.

    Args:
        job_config: Pipeline config dict from Airflow Variable 'job_config'.

    Returns:
        Configured SnowflakeHook instance.
    """
    return SnowflakeHook(
        snowflake_conn_id=job_config["conn_id"],
        database=job_config["database"],
        schema=job_config["schema"],
        role=job_config["role"],
    )


def _gcs_file_path(job_config: dict, table_name: str) -> str:
    """
    Build the stage-qualified path for a table's CSV file.

    Format : @<stage_name>/<gcs_folder>/<table_name>.csv
    Example: @RAW.gcs_stage/de-challenge-202605/meetup/categories.csv

    Args:
        job_config: Pipeline config dict from Airflow Variable 'job_config'.
        table_name: Table name (matches the CSV filename without extension).

    Returns:
        Stage path string used in INFER_SCHEMA and COPY INTO commands.
    """
    return (
        f"@{job_config['stage_name']}"
        f"/{job_config['gcs_folder']}"
        f"/{table_name}.csv"
    )


def create_or_replace_table(
    hook: SnowflakeHook,
    job_config: dict,
    table_name: str,
) -> None:
    """
    Drop and recreate a Snowflake table with schema inferred from the GCS CSV file.    

    Args:
        hook:       Configured SnowflakeHook instance.
        job_config: Pipeline config dict from Airflow Variable 'job_config'.
        table_name: Target Snowflake table name (matches CSV filename without .csv).
    """
    gcs_path = _gcs_file_path(job_config, table_name)
    sql = f"""
    CREATE OR REPLACE TABLE {job_config['schema']}.{table_name}
    USING TEMPLATE (
        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(
            INFER_SCHEMA(
                LOCATION    => '{gcs_path}',
                FILE_FORMAT => '{job_config['file_format_name']}'
            )
        )
    );
    """
    hook.run(sql)


def copy_into_table(
    hook: SnowflakeHook,
    job_config: dict,
    table_name: str,
) -> None:
    """
    Bulk load data from a GCS CSV file into the target Snowflake table.

    Args:
        hook:       Configured SnowflakeHook instance.
        job_config: Pipeline config dict from Airflow Variable 'job_config'.
        table_name: Target Snowflake table name (matches CSV filename without .csv).
    """
    gcs_path = _gcs_file_path(job_config, table_name)
    sql = f"""
    COPY INTO {job_config['schema']}.{table_name}
    FROM '{gcs_path}'
    FILE_FORMAT          = (FORMAT_NAME = '{job_config['file_format_name']}')
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
    ON_ERROR             = 'CONTINUE';
    """
    hook.run(sql)


def load_csv_to_snowflake(table_name: str, job_config: dict) -> None:
    """
    Full-refresh load of a GCS CSV file into a Snowflake RAW table.

    Steps:
      1. CREATE OR REPLACE TABLE with schema auto-detected by INFER_SCHEMA()
      2. COPY INTO from GCS with automatic column name matching

    Nothing is hardcoded — all config comes from job_config.

    Args:
        table_name: CSV filename without .csv extension; also the Snowflake table name.
        job_config: Dict from Airflow Variable 'job_config' containing:
                    conn_id, database, schema, role, stage_name,
                    file_format_name, gcs_bucket, gcs_folder.
    """
    hook = _get_hook(job_config)
    create_or_replace_table(hook, job_config, table_name)
    copy_into_table(hook, job_config, table_name)
