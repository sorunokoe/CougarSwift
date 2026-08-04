import Foundation
import os
import Supabase

private let logger = Logger(subsystem: "com.trackman.golfapp", category: "MXMetrics")

/// No-op auth storage — the metrics service does not need auth persistence.
private struct NoOpAuthStorage: AuthLocalStorage {
    func store(key _: String, value _: Data) {}
    func retrieve(key _: String) -> Data? { nil }
    func remove(key _: String) {}
}

/// Supabase implementation of `MetricsStorageService`.
/// Stores MetricKit performance and diagnostic data in Supabase PostgreSQL.
///
/// Credentials are injected at construction time — do not hard-code them in source.
/// Read them from `Info.plist` keys `SupabaseURL` and `SupabaseAnonKey`.
public final class SupabaseMetricsService: MetricsStorageService, @unchecked Sendable {
    private enum Tables {
        static let metrics = "app_metrics"
        static let diagnostics = "app_diagnostics"
    }

    private let client: SupabaseClient

    // MARK: - Initialization

    public init(supabaseURL: URL, supabaseKey: String) {
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: NoOpAuthStorage(),
                    autoRefreshToken: false,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    // MARK: - MetricsStorageService

    public func store(metrics: consuming AppMetrics) async throws {
        let record = MetricsRecord(from: metrics)
        try await client.from(Tables.metrics).insert(record).execute()
        logger.debug("Stored metrics: \(metrics.id)")
    }

    public func store(diagnostics: consuming AppDiagnostics) async throws {
        let record = DiagnosticsRecord(from: diagnostics)
        try await client.from(Tables.diagnostics).insert(record).execute()
        logger.debug("Stored diagnostics: \(diagnostics.id)")
    }
}
