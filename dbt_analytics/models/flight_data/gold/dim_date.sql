-- Gold dimension: Date dimension for time-based analysis
-- Grain: one row per date, spanning the range of flight data

with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="(select min(flight_date) from " ~ ref('silver_flights') ~ ")",
        end_date="(select dateadd(day, 1, max(flight_date)) from " ~ ref('silver_flights') ~ ")"
    ) }}

),

renamed as (

    select
        {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_key,
        date_day as date,

        year(date_day) as year,
        month(date_day) as month,
        day(date_day) as day_of_month,
        dayofweek(date_day) as day_of_week,
        dayname(date_day) as day_name,
        monthname(date_day) as month_name,
        quarter(date_day) as quarter,
        weekofyear(date_day) as week_of_year,

        case when dayofweek(date_day) in (0, 6) then true else false end as is_weekend

    from date_spine

)

select * from renamed
