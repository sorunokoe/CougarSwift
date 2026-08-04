import Foundation

// swiftlint:disable identifier_name
// Reason: snake_case column names match PostgreSQL column names intentionally

/// Flattened diagnostics record for PostgreSQL storage.
/// Column names use snake_case to match the Supabase table schema exactly.
struct DiagnosticsRecord: Encodable {
    let id: String
    let timestamp: Date
    let device_model: String
    let os_version: String
    let app_version: String
    let build_version: String

    let crash_count: Int
    let crashes_json: String?
    let hang_count: Int
    let hangs_json: String?
    let disk_exception_count: Int
    let disk_exceptions_json: String?
    let cpu_exception_count: Int
    let cpu_exceptions_json: String?

    init(from diagnostics: AppDiagnostics) {
        id = diagnostics.id
        timestamp = diagnostics.timestamp
        device_model = diagnostics.deviceModel
        os_version = diagnostics.osVersion
        app_version = diagnostics.appVersion
        build_version = diagnostics.buildVersion

        crash_count = diagnostics.crashDiagnostics.count
        crashes_json = encodeJSON(diagnostics.crashDiagnostics)
        hang_count = diagnostics.hangDiagnostics.count
        hangs_json = encodeJSON(diagnostics.hangDiagnostics)
        disk_exception_count = diagnostics.diskWriteExceptionDiagnostics.count
        disk_exceptions_json = encodeJSON(diagnostics.diskWriteExceptionDiagnostics)
        cpu_exception_count = diagnostics.cpuExceptionDiagnostics.count
        cpu_exceptions_json = encodeJSON(diagnostics.cpuExceptionDiagnostics)
    }
}

// swiftlint:enable identifier_name

private func encodeJSON<T: Encodable>(_ value: T?) -> String? {
    guard let value else { return nil }
    guard let data = try? JSONEncoder().encode(value) else { return nil }
    return String(data: data, encoding: .utf8)
}
