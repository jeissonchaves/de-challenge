{{ config(unique_key='CITY_ID') }}
select
    "city_id" as CITY_ID,
    trim("city") as CITY_NAME,
    trim("state") as STATE,
    trim("country") as COUNTRY,
    "latitude" as LATITUDE,
    "longitude" as LONGITUDE,
    "zip" as ZIP_CODE,
    trim("localized_country_name") as LOCALIZED_COUNTRY_NAME,
    "member_count" as MEMBER_COUNT,
    "ranking" as RANKING,
    CURRENT_TIMESTAMP() as LOADED_DATE
from {{ source('raw', 'cities') }}
