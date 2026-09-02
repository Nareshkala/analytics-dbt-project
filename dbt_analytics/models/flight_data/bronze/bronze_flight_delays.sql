-- Bronze layer: Raw flight delay and cancellation data
-- Grain: one row per source record (no dedup applied yet)
-- Incremental (append): _loaded_at is the S3 file's real last-modified time
-- (captured once at COPY INTO time), so reruns with no new files add nothing.

with source as (

    select *
    from {{ source('raw_flight_data', 'flight_delays') }}

),

base as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'year', 'month', 'day_of_month', 'carrier',
            'crs_dep_time', 'origin_airport_code', 'dest_airport_code'
        ]) }} as _bronze_row_id,

        year,
        month,
        day_of_month,
        day_of_week,
        carrier,
        crs_dep_time,
        dep_delay,
        dep_del15,
        crs_arr_time,
        arr_delay,
        arr_del15,
        cancelled,
        origin_airport_code,
        origin_airport_name,
        origin_latitude,
        origin_longitude,
        dest_airport_code,
        dest_airport_name,
        dest_latitude,
        dest_longitude,

        _copy_loaded_at as _loaded_at,
        _source_file_name

    from source

)

select * from base

{% if is_incremental() %}
where _loaded_at > (select coalesce(max(_loaded_at), '1900-01-01') from {{ this }})
{% endif %}