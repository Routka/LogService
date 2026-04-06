import Foundation
import Testing
@testable import LogService

struct LogServiceClientTests {
    @Test("Create log payload encodes creationDate with fractional seconds")
    func createLogPayloadUsesFractionalSeconds() throws {
        let client = LogServiceClient()
        let log = CreateAppLogRequest(
            id: "log-001",
            sessionID: "session-123",
            deviceID: "device-456",
            message: "Test payload",
            action: "paywall_opened",
            creationDate: Date(timeIntervalSince1970: 1_743_877_800.123),
            appVersion: "1.4.2",
            deviceType: "iPhone16,2",
            region: "US",
            locale: "en_US",
            type: "info",
            category: "navigation"
        )

        let data = try client.encodeForCreateLogRequest(log)
        let payload = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let creationDate = try #require(payload["creationDate"] as? String)

        #expect(creationDate == "2025-04-05T18:30:00.123Z")
    }
}
