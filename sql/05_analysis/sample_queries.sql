-- Top 5 zones by revenue
SELECT z.zone, z.borough, SUM(f.total_amount) AS total_revenue, COUNT(*) AS trip_count
FROM fct_trips f
JOIN dim_zone z ON f.pickup_zone_sk = z.zone_sk
GROUP BY z.zone, z.borough
ORDER BY total_revenue DESC
LIMIT 5;

-- Average tip by payment type
SELECT p.payment_type_desc, AVG(f.tip_amount) AS avg_tip, COUNT(*) AS trips
FROM fct_trips f
JOIN dim_payment_type p ON f.payment_type_key = p.payment_type_key
GROUP BY p.payment_type_desc
ORDER BY avg_tip DESC;

-- Daily trip trend
SELECT d.full_date, d.day_name, COUNT(*) AS trip_count, SUM(f.total_amount) AS daily_revenue
FROM fct_trips f
JOIN dim_date d ON f.pickup_date_key = d.date_key
GROUP BY d.full_date, d.day_name
ORDER BY d.full_date;