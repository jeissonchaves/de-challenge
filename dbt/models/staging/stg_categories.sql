{{ config(unique_key='CATEGORY_ID') }}
select
    "category_id" as CATEGORY_ID,
    trim("category_name") as CATEGORY_NAME,
    trim("shortname") as SHORTNAME,
    trim("sort_name") as SORT_NAME,
    CURRENT_TIMESTAMP() as LOADED_DATE
from {{ source('raw', 'categories') }}
