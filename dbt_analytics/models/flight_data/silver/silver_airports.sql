-- Silver layer: Cleaned airport reference data
-- Grain: one row per airport

{{ config(unique_key='airport_key') }}

with bronze as (

    select *
    from {{ ref('bronze_airport_locations') }}

),

deduped as (

    select
        *,
        row_number() over (
            partition by airport_code
            order by _loaded_at desc
        ) as _rn
    from bronze
    where airport_code is not null

),

cleaned as (

    select
        {{ dbt_utils.generate_surrogate_key(['airport_code']) }} as airport_key,

        upper(trim(airport_code)) as airport_code,
        initcap(trim(display_airport_name)) as display_airport_name,
        latitude::float as latitude,
        longitude::float as longitude,

        _loaded_at

    from deduped
    where _rn = 1

)

select * from cleaned