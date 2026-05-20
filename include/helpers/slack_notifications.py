from airflow.providers.slack.hooks.slack_webhook import SlackWebhookHook

def send_slack_success_alert(context):
    """
    Sends a success message to Slack when a DAG completes successfully.
    """
    ti = context.get('task_instance')
    dag_id = ti.dag_id
    execution_date = context.get('logical_date')
    
    slack_msg = f"""
:large_green_circle: *DAG Ejecutado Exitosamente*
*DAG:* `{dag_id}`
*Execution Time:* {execution_date}
    """
    
    slack_hook = SlackWebhookHook(
        slack_webhook_conn_id='slack_webhook'
    )
    slack_hook.send(text=slack_msg)

def send_slack_failure_alert(context):
    """
    Sends a failure message to Slack when a task fails.
    """
    ti = context.get('task_instance')
    dag_id = ti.dag_id
    task_id = ti.task_id
    log_url = ti.log_url
    
    slack_msg = f"""
:red_circle: *Fallo en Ejecución de Tarea*
*DAG:* `{dag_id}`
*Task Fallida:* `{task_id}`
*Logs:* <{log_url}|Click para ver los Logs en Airflow>
    """
    
    slack_hook = SlackWebhookHook(
        slack_webhook_conn_id='slack_webhook'
    )
    slack_hook.send(text=slack_msg)
