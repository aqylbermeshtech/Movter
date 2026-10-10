//
//  NetworkError.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Alamofire
import Foundation

public enum NetworkError: Error, LocalizedError {
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

    public var apiCode: String? {
        guard case let .apiError(_, _, code, _, _) = self else { return nil }
        return code
    }

    public var apiFields: [String] {
        guard case let .apiError(_, _, _, fields, _) = self else { return [] }
        return fields
    }

    public var apiDetails: String? {
        guard case let .apiError(_, _, _, _, details) = self else { return nil }
        let trimmed = details?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    public func hasAPICode(_ code: String) -> Bool {
        apiCode?.caseInsensitiveCompare(code) == .orderedSame
    }

    private struct GenericErrorResponse: Decodable {
        let statusMessage: String?
        let message: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case statusMessage = "status_message"
            case message
            case error
        }
    }

    public static func fromResponseBody(_ data: Data?, statusCode: Int) -> NetworkError? {
        guard let data, !data.isEmpty else { return nil }
        if let decoded = try? JSONDecoder().decode(GenericErrorResponse.self, from: data) {
            let msg = decoded.statusMessage ?? decoded.message ?? decoded.error ?? ""
            if !msg.isEmpty {
                return .apiError(
                    message: msg,
                    statusCode: statusCode,
                    apiCode: nil,
                    fields: [],
                    details: nil
                )
            }
        }
        return nil
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

