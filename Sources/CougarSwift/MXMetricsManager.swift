import Foundation
import MetricKit
import os
import Synchronization

private let logger = Logger(subsystem: "com.trackman.golfapp", category: "MXMetrics")

private let _shared: Mutex<MXMetricsManager?> = Mutex(nil)

/// Manager responsible for subscribing to MetricKit and handling metric payloads.
/// This class acts as the bridge between MetricKit and any storage backend.
///
/// Usage:
/// ```swift
/// MXMetricsManager.configure()
/// MXMetricsManager.shared?.startCollecting()
/// ```
public final class MXMetricsManager: NSObject, Sendable {
    /// Thread-safe access to the shared instance via `Synchronization.Mutex`.
    public static var shared: MXMetricsManager? {
        get { _shared.withLock { $0 } }
        set { _shared.withLock { $0 = newValue } }
    }

    private let metricsService: MetricsStorageService

    private init(service: MetricsStorageService) {
        metricsService = service
        super.init()
    }

    /// Configure `MXMetricsManager` by reading credentials from `Info.plist`.
    /// Add `SupabaseURL` and `SupabaseAnonKey` entries to your target's `Info.plist`.
    /// Call this early in the app lifecycle, before `startCollecting()`.
    public static func configure() {
        guard
            let urlString = Bundle.main.infoDictionary?["SupabaseURL"] as? String,
            let url = URL(string: urlString),
            let key = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String
        else {
            logger.error("Supabase credentials missing from Info.plist — metrics not configured")
            return
        }
        let service = SupabaseMetricsService(supabaseURL: url, supabaseKey: key)
        shared = MXMetricsManager(service: service)
        logger.info("Configured SupabaseMetricsService")
    }

    /// Configure `MXMetricsManager` with a custom storage service (e.g. for testing).
    public static func configure(with service: MetricsStorageService) {
        shared = MXMetricsManager(service: service)
        logger.info("Configured with \(String(describing: type(of: service)))")
    }

    /// Start collecting MetricKit metrics. Must call `configure()` first.
    public func startCollecting() {
        MXMetricManager.shared.add(self)
        logger.info("Started collecting metrics")
    }

    /// Stop collecting metrics.
    public func stopCollecting() {
        MXMetricManager.shared.remove(self)
        logger.info("Stopped collecting metrics")
    }

    #if DEBUG
        /// Send a test record to verify storage connection (DEBUG only).
        public func sendTestRecord() {
            Task.detached { [metricsService] in
                do {
                    let testMetrics = AppMetrics.makeTestRecord()
                    try await metricsService.store(metrics: testMetrics)
                    logger.info("Test record sent successfully")
                } catch {
                    logger.error("Test failed: \(error.localizedDescription)")
                }
            }
        }
    #endif
}

// MARK: - MXMetricManagerSubscriber

extension MXMetricsManager: MXMetricManagerSubscriber {
    /// Called when MetricKit delivers daily metric payloads (typically once per day).
    public func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            processMetricPayload(payload)
        }
    }

    /// Called when MetricKit delivers diagnostic payloads (crashes, hangs, disk writes).
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            processDiagnosticPayload(payload)
        }
    }

    private func processMetricPayload(_ payload: MXMetricPayload) {
        let metrics = AppMetrics(from: payload)
        Task.detached { [metricsService] in
            do {
                try await metricsService.store(metrics: metrics)
            } catch {
                logger.error("Failed to store metrics: \(error.localizedDescription)")
            }
        }
    }

    private func processDiagnosticPayload(_ payload: MXDiagnosticPayload) {
        let diagnostics = AppDiagnostics(from: payload)
        Task.detached { [metricsService] in
            do {
                try await metricsService.store(diagnostics: diagnostics)
            } catch {
                logger.error("Failed to store diagnostics: \(error.localizedDescription)")
            }
        }
    }
}
