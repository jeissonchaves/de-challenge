{{ config(unique_key=['MEMBER_ID', 'TOPIC_ID']) }}
select
    "member_id" as MEMBER_ID,
    "topic_id" as TOPIC_ID,
    trim("topic_key") as TOPIC_KEY,
    trim("topic_name") as TOPIC_NAME,
    CURRENT_TIMESTAMP() as LOADED_DATE
from {{ source('raw', 'members_topics') }}
