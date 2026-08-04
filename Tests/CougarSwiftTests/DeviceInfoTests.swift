import Testing
@testable import CougarSwift

@Suite("DeviceInfo")
struct DeviceInfoTests {
    @Test("model is non-empty string")
    func modelIsNonEmpty() {
        #expect(DeviceInfo.model.isEmpty == false)
    }

    @Test("osVersion has major.minor.patch format")
    func osVersionFormat() {
        let components = DeviceInfo.osVersion.split(separator: ".")
        #expect(components.count == 3)
    }

    @Test("appVersion returns string or unknown")
    func appVersionFallback() {
        #expect(DeviceInfo.appVersion.isEmpty == false)
    }

    @Test("buildVersion returns string or unknown")
    func buildVersionFallback() {
        #expect(DeviceInfo.buildVersion.isEmpty == false)
    }
}
