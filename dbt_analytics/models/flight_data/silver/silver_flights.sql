-- Silver layer: Cleaned flight data with calculated fields
-- Grain: one row per flight
-- Incremental (merge): only bronze rows newer than what's already in silver
-- (per _loaded_at, the real file-arrival timestamp) get reprocessed.

{{ config(unique_key='flight_key') }}

with bronze as (

    select *
    from {{ ref('bronze_flight_delays') }}

),

cleaned as (

    select
        _bronze_row_id as flight_key,

        try_to_date(
            lpad(year::string, 4, '0') || '-' ||
            lpad(month::string, 2, '0') || '-' ||
            lpad(day_of_month::string, 2, '0'),
            'YYYY-MM-DD'
        ) as flight_date,

        year,
        month,
        day_of_month,
        day_of_week,
        upper(trim(carrier)) as carrier,

        crs_dep_time,
        crs_arr_time,

        upper(trim(origin_airport_code)) as origin_airport_code,
        trim(origin_airport_name) as origin_airport_name,
        upper(trim(dest_airport_code)) as dest_airport_code,
        trim(dest_airport_name) as dest_airport_name,

        coalesce(dep_delay, 0) as dep_delay_minutes,
        coalesce(arr_delay, 0) as arr_delay_minutes,

        case when dep_del15 = 1 then true else false end as is_departure_delayed_15,
        case when arr_del15 = 1 then true else false end as is_arrival_delayed_15,
        case when cancelled = 1 then true else false end as is_cancelled,

        case
            when cancelled = 1 then 'CANCELLED'
            when coalesce(arr_delay, 0) >= 15 then 'DELAYED'
            when coalesce(arr_delay, 0) <= 0 then 'ON_TIME'
            else 'MINOR_DELAY'
        end as flight_status,

        _loaded_at

    from bronze
    where origin_airport_code is not null
      and dest_airport_code is not null

),


deduped as (

    select
        *,
        row_number() over (
            partition by flight_key
            order by _loaded_at desc
        ) as _rn
    from cleaned

)

select * exclude (_rn) from deduped
where _rn = 1

{% if is_incremental() %}
and _loaded_at > (select coalesce(max(_loaded_at), '1900-01-01') from {{ this }})
{% endif %}