import Foundation

/// Static helpers for reading device and app environment info.
enum DeviceInfo {
    static var model: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: info.machine) { bytes in
            bytes.prefix(while: { $0 != 0 })
                .compactMap { UInt8(exactly: $0).map { Character(UnicodeScalar($0)) } }
                .map(String.init)
                .joined()
        }
    }

    static var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    static var buildVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }
}
