{{ config(unique_key=['MEMBER_ID', 'GROUP_ID']) }}
select
    "member_id" as MEMBER_ID,
    trim("member_name") as MEMBER_NAME,
    trim("city") as CITY_NAME,
    trim("country") as COUNTRY,
    trim("hometown") as HOMETOWN,
    trim("state") as STATE,
    trim("member_status") as MEMBER_STATUS,
    trim("bio") as BIO,
    trim("link") as LINK,
    "visited" as VISITED_COUNT,
    "group_id" as GROUP_ID,
    "lat" as LATITUDE,
    "lon" as LONGITUDE,
    try_to_timestamp("joined"::string) as JOINED_AT,
    CURRENT_TIMESTAMP() as LOADED_DATE
from {{ source('raw', 'members') }}
