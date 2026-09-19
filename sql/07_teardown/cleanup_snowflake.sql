-- ============================================================
-- Snowflake Teardown / Cleanup
-- Purpose: safely suspend and verify compute resources after
-- finishing work on this project, so no credits are consumed
-- while the warehouse sits idle.
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE dev_wh;

-- Explicitly suspend the warehouse (in most cases AUTO_SUSPEND = 60
-- already does this automatically after 60 seconds of inactivity,
-- this is just an immediate, explicit stop)
ALTER WAREHOUSE dev_wh SUSPEND;

-- Confirm the warehouse state is now SUSPENDED before walking away
SHOW WAREHOUSES;

-- ------------------------------------------------------------
-- Full project teardown (run only when completely done with
-- the project, e.g. after pushing to GitHub and no longer
-- needing to query the data)
-- ------------------------------------------------------------
-- DROP DATABASE IF EXISTS portfolio_db;
-- DROP WAREHOUSE IF EXISTS dev_wh;
-- DROP INTEGRATION IF EXISTS s3_portfolio_int;
-- DROP RESOURCE MONITOR IF EXISTS trial_guard;
