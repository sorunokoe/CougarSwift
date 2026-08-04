import Foundation

// swiftlint:disable identifier_name
// Reason: snake_case column names match PostgreSQL column names intentionally

/// Flattened metrics record optimised for PostgreSQL storage and querying.
/// Column names use snake_case to match the Supabase table schema exactly.
struct MetricsRecord: Encodable {
    let id: String
    let timestamp: Date
    let device_model: String
    let os_version: String
    let app_version: String
    let build_version: String

    // Launch time histograms (raw JSON) and derived p50/p90 estimates (ms)
    let launch_time_histogram: String?
    let cold_launch_p50_ms: Double?
    let cold_launch_p90_ms: Double?
    let resume_time_histogram: String?
    let warm_launch_p50_ms: Double?
    let warm_launch_p90_ms: Double?
    let extended_launch_p50_ms: Double?
    let extended_launch_p90_ms: Double?

    // Hang time histogram and derived percentiles
    let hang_time_histogram: String?
    let hang_p50_ms: Double?
    let hang_p90_ms: Double?

    // App exit reasons — foreground
    let foreground_exit_count: Int?
    let abnormal_exit_count: Int?
    let watchdog_exit_count: Int?
    let memory_exit_count: Int?

    // App exit reasons — background
    let bg_memory_pressure_exit_count: Int?
    let bg_cpu_resource_limit_exit_count: Int?
    let bg_task_timeout_exit_count: Int?
    let bg_suspended_locked_file_exit_count: Int?

    // CPU
    let cpu_time_seconds: Double?
    let cpu_instructions: Double?

    // GPU
    let gpu_time_seconds: Double?

    // Memory
    let peak_memory_mb: Double?
    let avg_suspended_memory_mb: Double?

    // Disk
    let disk_writes_mb: Double?

    // Display & Animation
    let avg_pixel_luminance: Double?
    let scroll_hitch_ratio: Double?

    // Network
    let wifi_upload_mb: Double?
    let wifi_download_mb: Double?
    let cellular_upload_mb: Double?
    let cellular_download_mb: Double?

    // Location accuracy time buckets (seconds in each accuracy tier)
    let location_best_accuracy_seconds: Double?
    let location_navigation_seconds: Double?
    let location_ten_meters_seconds: Double?
    let location_hundred_meters_seconds: Double?
    let location_kilometer_seconds: Double?
    let location_three_km_seconds: Double?

    init(from metrics: AppMetrics) {
        id = metrics.id
        timestamp = metrics.timestamp
        device_model = metrics.deviceModel
        os_version = metrics.osVersion
        app_version = metrics.appVersion
        build_version = metrics.buildVersion

        // Launch histograms + derived percentiles
        let coldBuckets = metrics.launchTime?.histogrammedTimeToFirstDrawMS ?? []
        launch_time_histogram = encodeJSON(coldBuckets.isEmpty ? nil : coldBuckets)
        cold_launch_p50_ms = HistogramAnalysis.percentile(0.50, of: coldBuckets)
        cold_launch_p90_ms = HistogramAnalysis.percentile(0.90, of: coldBuckets)

        let resumeBuckets = metrics.resumeTime?.histogrammedResumeTimeMS ?? []
        resume_time_histogram = encodeJSON(resumeBuckets.isEmpty ? nil : resumeBuckets)
        warm_launch_p50_ms = metrics.launchTime.flatMap {
            HistogramAnalysis.percentile(0.50, of: $0.histogrammedOptimizedTimeToFirstDrawMS)
        }
        warm_launch_p90_ms = metrics.launchTime.flatMap {
            HistogramAnalysis.percentile(0.90, of: $0.histogrammedOptimizedTimeToFirstDrawMS)
        }
        extended_launch_p50_ms = metrics.launchTime.flatMap {
            HistogramAnalysis.percentile(0.50, of: $0.histogrammedExtendedLaunchMS)
        }
        extended_launch_p90_ms = metrics.launchTime.flatMap {
            HistogramAnalysis.percentile(0.90, of: $0.histogrammedExtendedLaunchMS)
        }

        // Hang percentiles
        let hangBuckets = metrics.hangTime?.histogrammedHangTimeMS ?? []
        hang_time_histogram = encodeJSON(hangBuckets.isEmpty ? nil : hangBuckets)
        hang_p50_ms = HistogramAnalysis.percentile(0.50, of: hangBuckets)
        hang_p90_ms = HistogramAnalysis.percentile(0.90, of: hangBuckets)

        // App exit reasons — foreground
        foreground_exit_count = metrics.appExitMetrics?.foregroundExitCount
        abnormal_exit_count = metrics.appExitMetrics?.abnormalExitCount
        watchdog_exit_count = metrics.appExitMetrics?.watchdogExitCount
        memory_exit_count = metrics.appExitMetrics?.memoryResourceLimitExitCount

        // App exit reasons — background
        bg_memory_pressure_exit_count = metrics.appExitMetrics?.backgroundMemoryPressureExitCount
        bg_cpu_resource_limit_exit_count = metrics.appExitMetrics?.backgroundCPUResourceLimitExitCount
        bg_task_timeout_exit_count = metrics.appExitMetrics?.backgroundTaskAssertionTimeoutExitCount
        bg_suspended_locked_file_exit_count = metrics.appExitMetrics?.backgroundSuspendedWithLockedFileExitCount

        // CPU & GPU
        cpu_time_seconds = metrics.cpuMetrics?.cumulativeCPUTimeSeconds
        cpu_instructions = metrics.cpuMetrics?.cumulativeCPUInstructions
        gpu_time_seconds = metrics.gpuMetrics?.cumulativeGPUTimeSeconds

        // Memory
        peak_memory_mb = metrics.memoryMetrics?.peakMemoryUsageMB
        avg_suspended_memory_mb = metrics.memoryMetrics?.averageSuspendedMemoryMB

        // Disk
        disk_writes_mb = metrics.diskIOMetrics?.cumulativeLogicalWritesMB

        // Display & Animation
        avg_pixel_luminance = metrics.displayMetrics?.averagePixelLuminance
        scroll_hitch_ratio = metrics.animationMetrics?.scrollHitchTimeRatio

        // Network
        wifi_upload_mb = metrics.networkTransferMetrics?.cumulativeWifiUploadMB
        wifi_download_mb = metrics.networkTransferMetrics?.cumulativeWifiDownloadMB
        cellular_upload_mb = metrics.networkTransferMetrics?.cumulativeCellularUploadMB
        cellular_download_mb = metrics.networkTransferMetrics?.cumulativeCellularDownloadMB

        // Location
        location_best_accuracy_seconds = metrics.locationActivityMetrics?.cumulativeBestAccuracyTimeSeconds
        location_navigation_seconds = metrics.locationActivityMetrics?.cumulativeBestAccuracyForNavigationTimeSeconds
        location_ten_meters_seconds = metrics.locationActivityMetrics?.cumulativeNearestTenMetersAccuracyTimeSeconds
        location_hundred_meters_seconds = metrics.locationActivityMetrics?.cumulativeHundredMetersAccuracyTimeSeconds
        location_kilometer_seconds = metrics.locationActivityMetrics?.cumulativeKilometerAccuracyTimeSeconds
        location_three_km_seconds = metrics.locationActivityMetrics?.cumulativeThreeKilometersAccuracyTimeSeconds
    }
}

// swiftlint:enable identifier_name

private func encodeJSON<T: Encodable>(_ value: T?) -> String? {
    guard let value else { return nil }
    guard let data = try? JSONEncoder().encode(value) else { return nil }
    return String(data: data, encoding: .utf8)
}
