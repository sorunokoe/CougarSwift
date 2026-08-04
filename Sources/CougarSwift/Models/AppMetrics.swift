import Foundation
import MetricKit

// MARK: - Histogram extraction helper

private func extractBuckets<U: Unit>(from histogram: MXHistogram<U>) -> [HistogramBucket] {
    var buckets: [HistogramBucket] = []
    let enumerator = histogram.bucketEnumerator
    while let bucket = enumerator.nextObject() as? MXHistogramBucket<U> {
        buckets.append(HistogramBucket(from: bucket))
    }
    return buckets
}

/// Represents app performance metrics collected from MetricKit
public struct AppMetrics: Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let deviceModel: String
    public let osVersion: String
    public let appVersion: String
    public let buildVersion: String

    // MARK: - Launch Metrics

    public let launchTime: LaunchTimeMetrics?
    public let resumeTime: ResumeTimeMetrics?

    // MARK: - Responsiveness Metrics

    public let hangTime: HangTimeMetrics?
    public let appExitMetrics: AppExitMetrics?

    // MARK: - Resource Usage Metrics

    public let cpuMetrics: CPUMetrics?
    public let gpuMetrics: GPUMetrics?
    public let memoryMetrics: MemoryMetrics?
    public let diskIOMetrics: DiskIOMetrics?

    // MARK: - Display Metrics

    public let displayMetrics: DisplayMetrics?

    // MARK: - Animation Metrics

    public let animationMetrics: AnimationMetrics?

    // MARK: - Network Metrics

    public let networkTransferMetrics: NetworkTransferMetrics?
    public let cellularConditionMetrics: CellularConditionMetrics?

    // MARK: - Location Metrics

    public let locationActivityMetrics: LocationActivityMetrics?

    public init(from payload: MXMetricPayload) {
        id = UUID().uuidString
        timestamp = payload.timeStampEnd
        deviceModel = DeviceInfo.model
        osVersion = DeviceInfo.osVersion
        appVersion = DeviceInfo.appVersion
        buildVersion = DeviceInfo.buildVersion

        // Launch metrics
        launchTime = payload.applicationLaunchMetrics.map { LaunchTimeMetrics(from: $0) }
        resumeTime = payload.applicationLaunchMetrics.map { ResumeTimeMetrics(from: $0) }

        // Responsiveness
        hangTime = payload.applicationResponsivenessMetrics.map { HangTimeMetrics(from: $0) }
        appExitMetrics = payload.applicationExitMetrics.map { AppExitMetrics(from: $0) }

        // Resources
        cpuMetrics = payload.cpuMetrics.map { CPUMetrics(from: $0) }
        gpuMetrics = payload.gpuMetrics.map { GPUMetrics(from: $0) }
        memoryMetrics = payload.memoryMetrics.map { MemoryMetrics(from: $0) }
        diskIOMetrics = payload.diskIOMetrics.map { DiskIOMetrics(from: $0) }

        // Display
        displayMetrics = payload.displayMetrics.map { DisplayMetrics(from: $0) }

        // Animation
        animationMetrics = payload.animationMetrics.map { AnimationMetrics(from: $0) }

        // Network
        networkTransferMetrics = payload.networkTransferMetrics.map { NetworkTransferMetrics(from: $0) }
        cellularConditionMetrics = payload.cellularConditionMetrics.map { CellularConditionMetrics(from: $0) }

        // Location
        locationActivityMetrics = payload.locationActivityMetrics.map { LocationActivityMetrics(from: $0) }
    }

}

#if DEBUG
extension AppMetrics {
    /// Creates a minimal stub record for verifying the Supabase storage connection.
    /// Only available in DEBUG builds — not compiled into release.
    static func makeTestRecord() -> AppMetrics {
        AppMetrics(
            id: "test-\(UUID().uuidString)",
            timestamp: Date(),
            deviceModel: DeviceInfo.model,
            osVersion: DeviceInfo.osVersion,
            appVersion: DeviceInfo.appVersion,
            buildVersion: DeviceInfo.buildVersion
        )
    }

    private init(
        id: String,
        timestamp: Date,
        deviceModel: String,
        osVersion: String,
        appVersion: String,
        buildVersion: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.buildVersion = buildVersion
        self.launchTime = nil
        self.resumeTime = nil
        self.hangTime = nil
        self.appExitMetrics = nil
        self.cpuMetrics = nil
        self.gpuMetrics = nil
        self.memoryMetrics = nil
        self.diskIOMetrics = nil
        self.displayMetrics = nil
        self.animationMetrics = nil
        self.networkTransferMetrics = nil
        self.cellularConditionMetrics = nil
        self.locationActivityMetrics = nil
    }
}
#endif

// MARK: - Launch Time Metrics

public struct LaunchTimeMetrics: Codable, Sendable {
    /// Cold launch: time from process start to first frame draw
    public let histogrammedTimeToFirstDrawMS: [HistogramBucket]
    /// Warm/optimised launch (prewarmed process): time to first frame
    public let histogrammedOptimizedTimeToFirstDrawMS: [HistogramBucket]
    /// Extended launch: time to first frame plus async data loading until
    /// `MXMetricManager.reportExtendedLaunchCompletion()` is called (iOS 16+)
    public let histogrammedExtendedLaunchMS: [HistogramBucket]

    public init(from metrics: MXAppLaunchMetric) {
        histogrammedTimeToFirstDrawMS = extractBuckets(from: metrics.histogrammedTimeToFirstDraw)
        histogrammedOptimizedTimeToFirstDrawMS = extractBuckets(from: metrics.histogrammedOptimizedTimeToFirstDraw)
        if #available(iOS 16, *) {
            histogrammedExtendedLaunchMS = extractBuckets(from: metrics.histogrammedExtendedLaunch)
        } else {
            histogrammedExtendedLaunchMS = []
        }
    }
}

// MARK: - Resume Time Metrics

public struct ResumeTimeMetrics: Codable, Sendable {
    public let histogrammedResumeTimeMS: [HistogramBucket]

    public init(from metrics: MXAppLaunchMetric) {
        histogrammedResumeTimeMS = extractBuckets(from: metrics.histogrammedApplicationResumeTime)
    }
}

// MARK: - Hang Time Metrics

public struct HangTimeMetrics: Codable, Sendable {
    public let histogrammedHangTimeMS: [HistogramBucket]

    public init(from metrics: MXAppResponsivenessMetric) {
        histogrammedHangTimeMS = extractBuckets(from: metrics.histogrammedApplicationHangTime)
    }
}

// MARK: - App Exit Metrics

public struct AppExitMetrics: Codable, Sendable {
    // Foreground exits
    public let foregroundExitCount: Int
    public let abnormalExitCount: Int
    public let watchdogExitCount: Int
    public let memoryResourceLimitExitCount: Int
    public let badAccessExitCount: Int
    public let illegalInstructionExitCount: Int
    // Background exits — previously missing fields added
    public let backgroundNormalExitCount: Int
    public let backgroundAbnormalExitCount: Int
    public let backgroundMemoryPressureExitCount: Int
    public let backgroundCPUResourceLimitExitCount: Int
    public let backgroundTaskAssertionTimeoutExitCount: Int
    public let backgroundSuspendedWithLockedFileExitCount: Int
    public let backgroundMemoryResourceLimitExitCount: Int
    public let backgroundBadAccessExitCount: Int
    public let backgroundIllegalInstructionExitCount: Int

    public init(from metrics: MXAppExitMetric) {
        let fg = metrics.foregroundExitData
        let bg = metrics.backgroundExitData
        foregroundExitCount = fg.cumulativeNormalAppExitCount + fg.cumulativeAbnormalExitCount
        abnormalExitCount = fg.cumulativeAbnormalExitCount
        watchdogExitCount = fg.cumulativeAppWatchdogExitCount
        memoryResourceLimitExitCount = fg.cumulativeMemoryResourceLimitExitCount
        badAccessExitCount = fg.cumulativeBadAccessExitCount
        illegalInstructionExitCount = fg.cumulativeIllegalInstructionExitCount
        backgroundNormalExitCount = bg.cumulativeNormalAppExitCount
        backgroundAbnormalExitCount = bg.cumulativeAbnormalExitCount
        backgroundMemoryPressureExitCount = bg.cumulativeMemoryPressureExitCount
        backgroundCPUResourceLimitExitCount = bg.cumulativeCPUResourceLimitExitCount
        backgroundTaskAssertionTimeoutExitCount = bg.cumulativeBackgroundTaskAssertionTimeoutExitCount
        backgroundSuspendedWithLockedFileExitCount = bg.cumulativeSuspendedWithLockedFileExitCount
        backgroundMemoryResourceLimitExitCount = bg.cumulativeMemoryResourceLimitExitCount
        backgroundBadAccessExitCount = bg.cumulativeBadAccessExitCount
        backgroundIllegalInstructionExitCount = bg.cumulativeIllegalInstructionExitCount
    }
}

// MARK: - GPU Metrics

public struct GPUMetrics: Codable, Sendable {
    public let cumulativeGPUTimeSeconds: Double

    public init(from metrics: MXGPUMetric) {
        cumulativeGPUTimeSeconds = metrics.cumulativeGPUTime.converted(to: .seconds).value
    }
}

// MARK: - CPU Metrics

public struct CPUMetrics: Codable, Sendable {
    public let cumulativeCPUTimeSeconds: Double
    public let cumulativeCPUInstructions: Double

    public init(from metrics: MXCPUMetric) {
        cumulativeCPUTimeSeconds = metrics.cumulativeCPUTime.converted(to: .seconds).value
        // cumulativeCPUInstructions is a Measurement<Unit> representing instruction count
        cumulativeCPUInstructions = metrics.cumulativeCPUInstructions.value
    }
}

// MARK: - Memory Metrics

public struct MemoryMetrics: Codable, Sendable {
    public let peakMemoryUsageMB: Double
    public let averageSuspendedMemoryMB: Double

    public init(from metrics: MXMemoryMetric) {
        peakMemoryUsageMB = metrics.peakMemoryUsage.converted(to: .megabytes).value
        averageSuspendedMemoryMB = metrics.averageSuspendedMemory.averageMeasurement.converted(to: .megabytes).value
    }
}

// MARK: - Disk IO Metrics

public struct DiskIOMetrics: Codable, Sendable {
    public let cumulativeLogicalWritesMB: Double

    public init(from metrics: MXDiskIOMetric) {
        cumulativeLogicalWritesMB = metrics.cumulativeLogicalWrites.converted(to: .megabytes).value
    }
}

// MARK: - Display Metrics

public struct DisplayMetrics: Codable, Sendable {
    public let averagePixelLuminance: Double?

    public init(from metrics: MXDisplayMetric) {
        averagePixelLuminance = metrics.averagePixelLuminance?.averageMeasurement.value
    }
}

// MARK: - Animation Metrics

public struct AnimationMetrics: Codable, Sendable {
    /// The scroll hitch time ratio value (ms per second of scrolling)
    public let scrollHitchTimeRatio: Double

    public init(from metrics: MXAnimationMetric) {
        // scrollHitchTimeRatio represents ms of hitch per second of scrolling
        scrollHitchTimeRatio = metrics.scrollHitchTimeRatio.value
    }
}

// MARK: - Network Transfer Metrics

public struct NetworkTransferMetrics: Codable, Sendable {
    public let cumulativeWifiUploadMB: Double
    public let cumulativeWifiDownloadMB: Double
    public let cumulativeCellularUploadMB: Double
    public let cumulativeCellularDownloadMB: Double

    public init(from metrics: MXNetworkTransferMetric) {
        cumulativeWifiUploadMB = metrics.cumulativeWifiUpload.converted(to: .megabytes).value
        cumulativeWifiDownloadMB = metrics.cumulativeWifiDownload.converted(to: .megabytes).value
        cumulativeCellularUploadMB = metrics.cumulativeCellularUpload.converted(to: .megabytes).value
        cumulativeCellularDownloadMB = metrics.cumulativeCellularDownload.converted(to: .megabytes).value
    }
}

// MARK: - Cellular Condition Metrics

public struct CellularConditionMetrics: Codable, Sendable {
    public let histogrammedCellularConditionTime: [HistogramBucket]

    public init(from metrics: MXCellularConditionMetric) {
        histogrammedCellularConditionTime = extractBuckets(from: metrics.histogrammedCellularConditionTime)
    }
}

// MARK: - Location Activity Metrics

public struct LocationActivityMetrics: Codable, Sendable {
    public let cumulativeBestAccuracyTimeSeconds: Double
    public let cumulativeBestAccuracyForNavigationTimeSeconds: Double
    public let cumulativeNearestTenMetersAccuracyTimeSeconds: Double
    public let cumulativeHundredMetersAccuracyTimeSeconds: Double
    public let cumulativeKilometerAccuracyTimeSeconds: Double
    public let cumulativeThreeKilometersAccuracyTimeSeconds: Double

    public init(from metrics: MXLocationActivityMetric) {
        cumulativeBestAccuracyTimeSeconds = metrics.cumulativeBestAccuracyTime.converted(to: .seconds).value
        cumulativeBestAccuracyForNavigationTimeSeconds = metrics.cumulativeBestAccuracyForNavigationTime.converted(to: .seconds).value
        cumulativeNearestTenMetersAccuracyTimeSeconds = metrics.cumulativeNearestTenMetersAccuracyTime.converted(to: .seconds).value
        cumulativeHundredMetersAccuracyTimeSeconds = metrics.cumulativeHundredMetersAccuracyTime.converted(to: .seconds).value
        cumulativeKilometerAccuracyTimeSeconds = metrics.cumulativeKilometerAccuracyTime.converted(to: .seconds).value
        cumulativeThreeKilometersAccuracyTimeSeconds = metrics.cumulativeThreeKilometersAccuracyTime.converted(to: .seconds).value
    }
}

// MARK: - Histogram Bucket

public struct HistogramBucket: Codable, Sendable {
    public let bucketStart: Double
    public let bucketEnd: Double
    public let bucketCount: Int

    public init(bucketStart: Double, bucketEnd: Double, bucketCount: Int) {
        self.bucketStart = bucketStart
        self.bucketEnd = bucketEnd
        self.bucketCount = bucketCount
    }

    public init<UnitType: Unit>(from bucket: MXHistogramBucket<UnitType>) {
        bucketStart = bucket.bucketStart.value
        bucketEnd = bucket.bucketEnd.value
        bucketCount = bucket.bucketCount
    }
}
