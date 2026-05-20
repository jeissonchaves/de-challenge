{{ config(unique_key='TOPIC_ID') }}
select
    "topic_id" as TOPIC_ID,
    trim("topic_name") as TOPIC_NAME,
    trim("description") as DESCRIPTION,
    trim("link") as LINK,
    "members" as MEMBERS_COUNT,
    trim("urlkey") as URLKEY,
    "main_topic_id" as MAIN_TOPIC_ID,
    CURRENT_TIMESTAMP() as LOADED_DATE
from {{ source('raw', 'topics') }}
