{% set start_date = var('dim_date_start_date', '2010-01-01') %}
{% set end_date = var('dim_date_end_date', '2035-12-31') %}
 
with date_spine as (
 
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="to_date('" ~ start_date ~ "')",
        end_date="to_date('" ~ end_date ~ "')"
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
 