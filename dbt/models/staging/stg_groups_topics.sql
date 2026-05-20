{{ config(unique_key=['GROUP_ID', 'TOPIC_ID']) }}
select
    "group_id" as GROUP_ID,
    "topic_id" as TOPIC_ID,
    trim("topic_key") as TOPIC_KEY,
    trim("topic_name") as TOPIC_NAME,
    CURRENT_TIMESTAMP() as LOADED_DATE
from {{ source('raw', 'groups_topics') }}
