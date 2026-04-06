import Foundation

//public typealias CreateAppLog = Components.Schemas.CreateAppLog
//public typealias AppLog = Components.Schemas.AppLog
//public typealias AppDevice = Components.Schemas.AppDevice
//public typealias AppSession = Components.Schemas.AppSession
//public typealias PaginatedLogsResponse = Components.Schemas.PaginatedLogsResponse
//public typealias PaginatedDevicesResponse = Components.Schemas.PaginatedDevicesResponse
//public typealias PaginatedSessionsResponse = Components.Schemas.PaginatedSessionsResponse
//public typealias LogServiceErrorResponse = Components.Schemas.ErrorResponse

public enum LogServiceClientError: LocalizedError {
    case unexpectedStatusCode(Int, reason: String?)
    case badResponce(Data?, reason: String?)

    public var errorDescription: String? {
        switch self {
        case let .unexpectedStatusCode(statusCode, reason):
            return reason ?? "The log service returned HTTP \(statusCode)."
        }
    }
}
