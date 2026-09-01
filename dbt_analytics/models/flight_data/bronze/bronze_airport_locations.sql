-- Bronze layer: Raw airport location data ingested from S3
-- Grain: one row per source record (no dedup applied yet)
-- Incremental (append): _loaded_at is the S3 file's real last-modified time
-- (captured once at COPY INTO time), so reruns with no new files add nothing.

with source as (

    select *
    from {{ source('raw_flight_data', 'airport_locations') }}

),

renamed as (

    select
        {{ dbt_utils.generate_surrogate_key(['airport_id', 'airport_code']) }} as _bronze_row_id,

        airport_id,
        airport_code,
        display_airport_name,
        latitude,
        longitude,

        _copy_loaded_at as _loaded_at,
        _source_file_name

    from source

)

select * from renamed

{% if is_incremental() %}
where _loaded_at > (select coalesce(max(_loaded_at), '1900-01-01') from {{ this }})
{% endif %}