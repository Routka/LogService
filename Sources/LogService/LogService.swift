import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public struct CustomDateTranscoder: DateTranscoder {
    public init() {}

    public func encode(_ date: Date) throws -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    public func decode(_ date: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsedDate = formatter.date(from: date) {
            return parsedDate
            
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let parsedDate = formatter.date(from: date) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "Invalid date: \(date)")
                )
            }
            return parsedDate
        }
        
    }
}

public struct LogServiceClient {
    private let client: Client

    public init(
        serverURL: URL = (try? Servers.Server1.url()) ?? URL(string: "http://localhost:8080")!,
        configuration: Configuration = .init(dateTranscoder: CustomDateTranscoder()),
        transport: any ClientTransport = URLSessionTransport(),
        middlewares: [any ClientMiddleware] = []
    ) {
        self.client = Client(
            serverURL: serverURL,
            configuration: configuration,
            transport: transport,
            middlewares: middlewares
        )
    }

    public func createLog(_ log: CreateAppLog) async throws -> Operations.CreateLogs.Output.Created.Body.JsonPayload {
        let input = Operations.CreateLogs.Input(
            body: .json(.CreateAppLog(log))
        )
        let response = try await client.createLogs(input)
        return try createdPayload(from: response)
    }

    public func createLogs(_ logs: [CreateAppLog]) async throws -> Operations.CreateLogs.Output.Created.Body.JsonPayload {
        let input = Operations.CreateLogs.Input(
            body: .json(.case2(logs))
        )
        let response = try await client.createLogs(input)
        return try createdPayload(from: response)
    }

    public func createCompressedLogs(_ data: Data) async throws -> Operations.CreateLogs.Output.Created.Body.JsonPayload {
        let input = Operations.CreateLogs.Input(
            body: .applicationGzip(HTTPBody(data))
        )
        let response = try await client.createLogs(input)
        return try createdPayload(from: response)
    }

    public func fetchLogs(
        limit: Int = 50,
        offset: Int = 0,
        deviceID: String? = nil,
        sessionID: String? = nil
    ) async throws -> PaginatedLogsResponse {
        let query = Operations.ListLogs.Input.Query(
            limit: limit,
            offset: offset,
            deviceID: deviceID,
            sessionID: sessionID
        )
        let input = Operations.ListLogs.Input(query: query)
        let response = try await client.listLogs(input)
        switch response {
        case let .ok(result):
            switch result.body {
            case let .json(result):
                return result
            }
        case let .badRequest(badResponse):
            throw LogServiceClientError.badResponse(
                try? JSONEncoder().encode(badResponse.body.json),
                reason: try badResponse.body.json.reason
            )
        case let .undocumented(statusCode, _):
            throw LogServiceClientError.unexpectedStatusCode(statusCode, reason: nil)
        }
    }

    public func fetchDevices(limit: Int = 50, offset: Int = 0) async throws -> PaginatedDevicesResponse {
        let query = Operations.ListDevices.Input.Query(limit: limit, offset: offset)
        let input = Operations.ListDevices.Input(query: query)
        let response = try await client.listDevices(input)
        switch response {
        case let .ok(result):
            switch result.body {
            case let .json(result):
                return result
            }
        case let .badRequest(badResponse):
            throw LogServiceClientError.badResponse(
                try? JSONEncoder().encode(badResponse.body.json),
                reason: try badResponse.body.json.reason
            )
        case let .undocumented(statusCode, _):
            throw LogServiceClientError.unexpectedStatusCode(statusCode, reason: nil)
        }
    }
    public func fetchSessions(
        deviceID: String,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> PaginatedSessionsResponse {
        let input = Operations.ListSessionsForDevice.Input(
            path: .init(deviceID: deviceID),
            query: .init(limit: limit, offset: offset)
        )
        let response = try await client.listSessionsForDevice(input)
        switch response {
        case let .ok(result):
            switch result.body {
            case let .json(result):
                return result
            }
        case let .badRequest(badResponse):
            throw LogServiceClientError.badResponse(
                try? JSONEncoder().encode(badResponse.body.json),
                reason: try badResponse.body.json.reason
            )
        case let .undocumented(statusCode, _):
            throw LogServiceClientError.unexpectedStatusCode(statusCode, reason: nil)
        }
    }

    private func createdPayload(
        from response: Operations.CreateLogs.Output
    ) throws -> Operations.CreateLogs.Output.Created.Body.JsonPayload {
        switch response {
        case let .created(result):
            return try result.body.json
        case let .badRequest(badResponse):
            throw LogServiceClientError.badResponse(
                try? JSONEncoder().encode(badResponse.body.json),
                reason: try badResponse.body.json.reason
            )
        case let .contentTooLarge(errorResponse):
            throw LogServiceClientError.unexpectedStatusCode(
                413,
                reason: try errorResponse.body.json.reason
            )
        case let .undocumented(statusCode, _):
            throw LogServiceClientError.unexpectedStatusCode(statusCode, reason: nil)
        }
    }
}
