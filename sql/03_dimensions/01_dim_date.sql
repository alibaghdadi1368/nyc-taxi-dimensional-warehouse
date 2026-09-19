USE SCHEMA analytics;

CREATE OR REPLACE TABLE dim_date AS
SELECT
  TO_NUMBER(TO_CHAR(d, 'YYYYMMDD')) AS date_key,
  d AS full_date,
  YEAR(d) AS year,
  MONTH(d) AS month,
  DAY(d) AS day,
  DAYNAME(d) AS day_name,
  CASE WHEN DAYOFWEEK(d) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend
FROM (
  SELECT DATEADD(day, SEQ4(), '2023-01-01') AS d
  FROM TABLE(GENERATOR(ROWCOUNT => 365))
);