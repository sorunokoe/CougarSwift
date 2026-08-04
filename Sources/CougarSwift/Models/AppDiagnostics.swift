import Foundation
import MetricKit

/// Represents diagnostic data collected from MetricKit (crashes, hangs, disk writes)
public struct AppDiagnostics: Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let deviceModel: String
    public let osVersion: String
    public let appVersion: String
    public let buildVersion: String

    public let crashDiagnostics: [CrashDiagnostic]
    public let hangDiagnostics: [HangDiagnostic]
    public let diskWriteExceptionDiagnostics: [DiskWriteExceptionDiagnostic]
    public let cpuExceptionDiagnostics: [CPUExceptionDiagnostic]

    public init(from payload: MXDiagnosticPayload) {
        id = UUID().uuidString
        timestamp = payload.timeStampEnd
        deviceModel = DeviceInfo.model
        osVersion = DeviceInfo.osVersion
        appVersion = DeviceInfo.appVersion
        buildVersion = DeviceInfo.buildVersion

        crashDiagnostics = payload.crashDiagnostics?.map { CrashDiagnostic(from: $0) } ?? []
        hangDiagnostics = payload.hangDiagnostics?.map { HangDiagnostic(from: $0) } ?? []
        diskWriteExceptionDiagnostics = payload.diskWriteExceptionDiagnostics?.map { DiskWriteExceptionDiagnostic(from: $0) } ?? []
        cpuExceptionDiagnostics = payload.cpuExceptionDiagnostics?.map { CPUExceptionDiagnostic(from: $0) } ?? []
    }

// MARK: - Crash Diagnostic

public struct CrashDiagnostic: Codable, Sendable {
    public let exceptionType: Int?
    public let exceptionCode: Int?
    public let signal: Int?
    public let terminationReason: String?
    public let virtualMemoryRegionInfo: String?
    public let callStackTree: String?

    public init(from diagnostic: MXCrashDiagnostic) {
        exceptionType = diagnostic.exceptionType?.intValue
        exceptionCode = diagnostic.exceptionCode?.intValue
        signal = diagnostic.signal?.intValue
        terminationReason = diagnostic.terminationReason
        virtualMemoryRegionInfo = diagnostic.virtualMemoryRegionInfo

        // Convert call stack tree to JSON string for storage
        let callStackData = diagnostic.callStackTree.jsonRepresentation()
        callStackTree = String(data: callStackData, encoding: .utf8)
    }
}

// MARK: - Hang Diagnostic

public struct HangDiagnostic: Codable, Sendable {
    public let hangDurationSeconds: Double
    public let callStackTree: String?

    public init(from diagnostic: MXHangDiagnostic) {
        hangDurationSeconds = diagnostic.hangDuration.converted(to: .seconds).value

        let callStackData = diagnostic.callStackTree.jsonRepresentation()
        callStackTree = String(data: callStackData, encoding: .utf8)
    }
}

// MARK: - Disk Write Exception Diagnostic

public struct DiskWriteExceptionDiagnostic: Codable, Sendable {
    public let totalWritesCausedMB: Double
    public let callStackTree: String?

    public init(from diagnostic: MXDiskWriteExceptionDiagnostic) {
        totalWritesCausedMB = diagnostic.totalWritesCaused.converted(to: .megabytes).value

        let callStackData = diagnostic.callStackTree.jsonRepresentation()
        callStackTree = String(data: callStackData, encoding: .utf8)
    }
}

// MARK: - CPU Exception Diagnostic

public struct CPUExceptionDiagnostic: Codable, Sendable {
    public let totalCPUTimeSeconds: Double
    public let totalSampledTimeSeconds: Double
    public let callStackTree: String?

    public init(from diagnostic: MXCPUExceptionDiagnostic) {
        totalCPUTimeSeconds = diagnostic.totalCPUTime.converted(to: .seconds).value
        totalSampledTimeSeconds = diagnostic.totalSampledTime.converted(to: .seconds).value

        let callStackData = diagnostic.callStackTree.jsonRepresentation()
        callStackTree = String(data: callStackData, encoding: .utf8)
    }
}
