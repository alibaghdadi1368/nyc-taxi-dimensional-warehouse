CREATE OR REPLACE TABLE dim_zone (
  zone_sk INT AUTOINCREMENT,
  location_id INT,
  borough STRING,
  zone STRING,
  service_zone STRING,
  effective_date DATE,
  expiration_date DATE,
  is_current BOOLEAN
);

INSERT INTO dim_zone (location_id, borough, zone, service_zone, effective_date, expiration_date, is_current)
SELECT
  location_id, borough, zone, service_zone,
  '2023-01-01', '9999-12-31', TRUE
FROM raw.raw_taxi_zones;

-- SCD Type 2 simulation: a change in zone classification
CREATE OR REPLACE TEMPORARY TABLE zone_updates AS
SELECT location_id, borough, zone, service_zone
FROM raw.raw_taxi_zones
WHERE location_id = 1;

UPDATE zone_updates SET borough = 'Newark Metro Area' WHERE location_id = 1;

MERGE INTO dim_zone tgt
USING zone_updates src
ON tgt.location_id = src.location_id AND tgt.is_current = TRUE
WHEN MATCHED AND (tgt.borough != src.borough) THEN
  UPDATE SET expiration_date = CURRENT_DATE(), is_current = FALSE;

INSERT INTO dim_zone (location_id, borough, zone, service_zone, effective_date, expiration_date, is_current)
SELECT location_id, borough, zone, service_zone, CURRENT_DATE(), '9999-12-31', TRUE
FROM zone_updates src
WHERE NOT EXISTS (
  SELECT 1 FROM dim_zone tgt
  WHERE tgt.location_id = src.location_id AND tgt.is_current = TRUE
);

-- Verification: two rows should appear for location_id = 1
SELECT * FROM dim_zone WHERE location_id = 1 ORDER BY effective_date;