-- 001_initial_schema.sql
-- MetricKit performance monitoring schema for Supabase
-- Run this in the Supabase SQL Editor or via `supabase db push`

CREATE TABLE IF NOT EXISTS app_metrics (
    id               TEXT PRIMARY KEY,
    timestamp        TIMESTAMPTZ NOT NULL,
    device_model     TEXT NOT NULL,
    os_version       TEXT NOT NULL,
    app_version      TEXT NOT NULL,
    build_version    TEXT NOT NULL,

    -- Launch time histograms (raw JSON) and derived percentile estimates (ms)
    launch_time_histogram      TEXT,
    cold_launch_p50_ms         DOUBLE PRECISION,
    cold_launch_p90_ms         DOUBLE PRECISION,
    resume_time_histogram      TEXT,
    warm_launch_p50_ms         DOUBLE PRECISION,
    warm_launch_p90_ms         DOUBLE PRECISION,
    extended_launch_p50_ms     DOUBLE PRECISION,
    extended_launch_p90_ms     DOUBLE PRECISION,

    -- Hang time histogram and percentiles
    hang_time_histogram        TEXT,
    hang_p50_ms                DOUBLE PRECISION,
    hang_p90_ms                DOUBLE PRECISION,

    -- App exit reasons — foreground
    foreground_exit_count      INTEGER,
    abnormal_exit_count        INTEGER,
    watchdog_exit_count        INTEGER,
    memory_exit_count          INTEGER,

    -- App exit reasons — background (previously missing from the schema)
    bg_memory_pressure_exit_count        INTEGER,
    bg_cpu_resource_limit_exit_count     INTEGER,
    bg_task_timeout_exit_count           INTEGER,
    bg_suspended_locked_file_exit_count  INTEGER,

    -- CPU
    cpu_time_seconds           DOUBLE PRECISION,
    cpu_instructions           DOUBLE PRECISION,

    -- GPU (previously missing from the schema)
    gpu_time_seconds           DOUBLE PRECISION,

    -- Memory
    peak_memory_mb             DOUBLE PRECISION,
    avg_suspended_memory_mb    DOUBLE PRECISION,

    -- Disk
    disk_writes_mb             DOUBLE PRECISION,

    -- Display & Animation
    avg_pixel_luminance        DOUBLE PRECISION,
    scroll_hitch_ratio         DOUBLE PRECISION,

    -- Network
    wifi_upload_mb             DOUBLE PRECISION,
    wifi_download_mb           DOUBLE PRECISION,
    cellular_upload_mb         DOUBLE PRECISION,
    cellular_download_mb       DOUBLE PRECISION,

    -- Location accuracy time buckets (seconds spent at each accuracy tier)
    location_best_accuracy_seconds        DOUBLE PRECISION,
    location_navigation_seconds           DOUBLE PRECISION,
    location_ten_meters_seconds           DOUBLE PRECISION,
    location_hundred_meters_seconds       DOUBLE PRECISION,
    location_kilometer_seconds            DOUBLE PRECISION,
    location_three_km_seconds             DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS app_diagnostics (
    id               TEXT PRIMARY KEY,
    timestamp        TIMESTAMPTZ NOT NULL,
    device_model     TEXT NOT NULL,
    os_version       TEXT NOT NULL,
    app_version      TEXT NOT NULL,
    build_version    TEXT NOT NULL,
    crash_count      INTEGER NOT NULL DEFAULT 0,
    crashes_json     TEXT,
    hang_count       INTEGER NOT NULL DEFAULT 0,
    hangs_json       TEXT,
    disk_exception_count  INTEGER NOT NULL DEFAULT 0,
    disk_exceptions_json  TEXT,
    cpu_exception_count   INTEGER NOT NULL DEFAULT 0,
    cpu_exceptions_json   TEXT
);

-- Indexes for dashboard queries (time-range filtering and version breakdown)
CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON app_metrics (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_app_version ON app_metrics (app_version, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_diagnostics_timestamp ON app_diagnostics (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_diagnostics_app_version ON app_diagnostics (app_version, timestamp DESC);
