//
//  NetworkError.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

@preconcurrency import Alamofire
import Foundation

nonisolated public enum NetworkError: Error, LocalizedError {
    case missingURL
    case invalidResponse
    case noData
    case noInternetConnection
    case serverError(Int)
    case unauthorized
    case forbidden
    case notFound
    case decodingError
    case decodingFailed(Error)
    case encodingError
    case encodingFailed(Error)
    case timeoutError
    case apiError(message: String, statusCode: Int, apiCode: String?, fields: [String], details: String?)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .missingURL, .invalidResponse, .noData, .decodingError, .decodingFailed,
             .encodingError, .encodingFailed:
            return NetworkErrorCopy.generic
        case .noInternetConnection:
            return NetworkErrorCopy.noInternet
        case .serverError:
            return NetworkErrorCopy.server
        case .unauthorized, .forbidden:
            return NetworkErrorCopy.unauthorized
        case .notFound:
            return NetworkErrorCopy.notFound
        case .timeoutError:
            return NetworkErrorCopy.timeout
        case .apiError(let message, _, _, _, _):
            return message.isEmpty ? NetworkErrorCopy.generic : message
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    public var statusCode: Int? {
        switch self {
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .serverError(let code):
            return code
        case .apiError(_, let code, _, _, _):
            return code
        default:
            return nil
        }
    }

    public var isNotFound: Bool {
        statusCode == 404
    }

    public var isUnauthorized: Bool {
        statusCode == 401
    }

    /// Machine readable code the backend puts in `error.code`, used to tell apart
    /// outcomes that share a status code such as `RATE_LIMIT_EXCEEDED` and `AI_QUOTA_EXCEEDED`.
    public var apiCode: String? {
        guard case let .apiError(_, _, code, _, _) = self else { return nil }
        return code
    }

    /// Fields the backend named as missing, for example the sections a mentor profile
    /// still needs before it can be published.
    public var apiFields: [String] {
        guard case let .apiError(_, _, _, fields, _) = self else { return [] }
        return fields
    }

    /// Free-form diagnostic text from `error.details`; never a branching key and never
    /// shown to the user, it only makes a report or a log line readable.
    public var apiDetails: String? {
        guard case let .apiError(_, _, _, _, details) = self else { return nil }
        let trimmed = details?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    public func hasAPICode(_ code: String) -> Bool {
        apiCode?.caseInsensitiveCompare(code) == .orderedSame
    }

    /// The backend sends `error` as an object on fixed routes, as a `"CODE: text"` string in
    /// legacy ones and sometimes as `null`. A code or a field list alone is enough to build the
    /// error: the machine-readable part must survive even when `message` is empty.
    public static func fromResponseBody(_ data: Data?, statusCode: Int) -> NetworkError? {
        guard let data, !data.isEmpty else { return nil }
        guard let envelope = try? JSONDecoder().decode(APIErrorEnvelopeDTO.self, from: data) else { return nil }
        let code = envelope.errorCode
        let fields = envelope.errorFields
        let message = envelope.userFacingMessage
        guard message != nil || code != nil || !fields.isEmpty else { return nil }
        return .apiError(
            message: message ?? "",
            statusCode: statusCode,
            apiCode: code,
            fields: fields,
            details: envelope.error?.details
        )
    }
}

extension NetworkError {
    public static func from(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }

        if let afError = error as? AFError {
            switch afError {
            case let .requestRetryFailed(retryError: retryError, originalError: originalError):
                let retryMapped = NetworkError.from(retryError)
                switch retryMapped {
                case .notFound, .unauthorized, .forbidden, .serverError:
                    return retryMapped
                default:
                    return NetworkError.from(originalError)
                }
            case .sessionTaskFailed(let sessionError):
                if let urlError = sessionError as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        return .timeoutError
                    case .notConnectedToInternet, .networkConnectionLost:
                        return .noInternetConnection
                    default:
                        return .unknown(urlError)
                    }
                }
                return .unknown(sessionError)
            case .responseValidationFailed(let reason):
                switch reason {
                case .unacceptableStatusCode(let code):
                    switch code {
                    case 401:
                        return .unauthorized
                    case 403:
                        return .forbidden
                    case 404:
                        return .notFound
                    case 500...599:
                        return .serverError(code)
                    default:
                        return .serverError(code)
                    }
                default:
                    return .unknown(afError)
                }
            case .responseSerializationFailed:
                return .decodingFailed(afError)
            default:
                return .unknown(afError)
            }
        }

        if error._code == NSURLErrorTimedOut {
            return .timeoutError
        }

        if error._code == NSURLErrorNotConnectedToInternet {
            return .noInternetConnection
        }

        return .unknown(error)
    }
}

