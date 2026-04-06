import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

struct CustomDateTranscoder: DateTranscoder {
    
    func encode(_ date: Date) throws -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    func decode(_ date: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: date) {
            return date
        } else {
            throw EncodingError.invalidValue("Invalid date: \(date)", EncodingError.Context(codingPath: [], debugDescription: "Invalid date: \(date)"))
        }
    }
    
    
}

public struct LogServiceClient {
    private let client: Client
    init() {
        self.client = Client(
            serverURL: try! Servers.Server1.url(),
            configuration: .init(dateTranscoder: CustomDateTranscoder()),
            transport: URLSessionTransport()
        )
    }
    typealias DeviceModel = Components.Schemas.AppDevice
    typealias PaginatedDevicesList = Components.Schemas.PaginatedDevicesResponse
    
    func fetchDevices(limit: Int = 50, offset: Int = 0) async throws -> PaginatedDevicesList {
        let query: Operations.ListDevices.Input.Query = .init(limit: limit, offset: offset)
        let input: Operations.ListDevices.Input = .init(query: query)
        let responce = try await client.listDevices(input)
        switch responce {
        case .ok(let result):
            switch result.body {
            case .json(let result):
                return result
            }
        case .badRequest(let badResponce):
            let reason = try? badResponce.body.json.reason
            let data = try? badResponce.body.json.additionalProperties.value
           // TODO: Throw correct error
        case .undocumented(statusCode: let statusCode, let payload):
            print("Unknown error: \(statusCode)\n \(payload)")
            // TODO: Throw correct Error
        }
    }
}

