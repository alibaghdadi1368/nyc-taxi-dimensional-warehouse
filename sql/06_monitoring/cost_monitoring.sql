-- ============================================================
-- Cost Monitoring Queries
-- Purpose: check Snowflake credit consumption for this project's
-- warehouse, to stay well within free trial credits.
-- ============================================================

-- 1. Recent warehouse metering history (last 10 entries, most recent first)
--    Note: ACCOUNT_USAGE views can lag up to ~1-3 hours behind real-time
--    activity, so numbers here may not reflect the very latest queries yet.
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
ORDER BY START_TIME DESC
LIMIT 10;

-- 2. Total credits consumed by this project's warehouse since creation
SELECT SUM(CREDITS_USED) AS total_credit_usage
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'DEV_WH';

-- 3. Current state of all warehouses in the account
--    (confirms DEV_WH is SUSPENDED when not actively in use,
--    which is what AUTO_SUSPEND = 60 is designed to guarantee)
SHOW WAREHOUSES;
