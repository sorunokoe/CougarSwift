-- 002_add_new_columns.sql
-- Adds columns introduced in CougarSwift refactor (p50/p90 percentiles,
-- GPU time, additional background exit reasons).
-- Safe to run multiple times (ADD COLUMN IF NOT EXISTS).

-- Launch time percentiles
ALTER TABLE app_metrics
    ADD COLUMN IF NOT EXISTS cold_launch_p50_ms     DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS cold_launch_p90_ms     DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS warm_launch_p50_ms     DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS warm_launch_p90_ms     DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS extended_launch_p50_ms DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS extended_launch_p90_ms DOUBLE PRECISION;

-- Hang time percentiles
ALTER TABLE app_metrics
    ADD COLUMN IF NOT EXISTS hang_p50_ms DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS hang_p90_ms DOUBLE PRECISION;

-- GPU time (previously missing)
ALTER TABLE app_metrics
    ADD COLUMN IF NOT EXISTS gpu_time_seconds DOUBLE PRECISION;

-- Background exit reasons (previously missing)
ALTER TABLE app_metrics
    ADD COLUMN IF NOT EXISTS bg_memory_pressure_exit_count       INTEGER,
    ADD COLUMN IF NOT EXISTS bg_cpu_resource_limit_exit_count    INTEGER,
    ADD COLUMN IF NOT EXISTS bg_task_timeout_exit_count          INTEGER,
    ADD COLUMN IF NOT EXISTS bg_suspended_locked_file_exit_count INTEGER;

-- Rename old combined exit count columns if they exist under old names
-- (only needed if the table was created before the refactor)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'app_metrics' AND column_name = 'background_exit_count'
    ) THEN
        ALTER TABLE app_metrics RENAME COLUMN background_exit_count TO bg_normal_exit_count;
    END IF;
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'app_metrics' AND column_name = 'normal_exit_count'
    ) THEN
        ALTER TABLE app_metrics DROP COLUMN normal_exit_count;
    END IF;
END $$;

-- Verify
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'app_metrics'
ORDER BY ordinal_position;
