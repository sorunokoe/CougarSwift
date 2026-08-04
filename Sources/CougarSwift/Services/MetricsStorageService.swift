import Foundation

/// Protocol defining the interface for storing metrics data
public protocol MetricsStorageService: Sendable {
    /// Store app performance metrics (consuming ownership)
    func store(metrics: consuming AppMetrics) async throws

    /// Store app diagnostic data (consuming ownership)
    func store(diagnostics: consuming AppDiagnostics) async throws
}
