//
//  NetworkManager.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Alamofire
import Foundation
//import MentorCore
//import MentorStorage

public protocol NetworkManagerProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws
}

public final class NetworkManager: NetworkManagerProtocol {
    public static let shared = NetworkManager()

    private let session: Session
    private let logger: LoggerProtocol

    public init(logger: LoggerProtocol? = nil) {
        let resolvedLogger = logger ?? DIContainer.shared.resolve(LoggerProtocol.self) ?? Logger()
        self.logger = resolvedLogger

        let authInterceptor = AuthenticationInterceptor(logger: resolvedLogger)
        let loggingInterceptor = LoggingInterceptor(logger: resolvedLogger)
        let errorInterceptor = ErrorHandlingInterceptor(logger: resolvedLogger)

        // Configure session with interceptors
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.urlCache = URLCache.shared
        configuration.requestCachePolicy = .useProtocolCachePolicy

        self.session = Session(
            configuration: configuration,
            interceptor: Interceptor(
                adapters: [authInterceptor, errorInterceptor],
                retriers: [authInterceptor, errorInterceptor]
            ),
            eventMonitors: [loggingInterceptor]
        )
    }

    private convenience init() {
        self.init(logger: nil)
    }

    public func request<T: Codable & Sendable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        let urlRequest = try endpoint.asURLRequest()

        return try await withCheckedThrowingContinuation { continuation in
            session.request(urlRequest)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: Self.mappedError(error, response: response.response, data: response.data))
                    }
                }
        }
    }

    public func request(_ endpoint: APIEndpoint) async throws {
        let urlRequest = try endpoint.asURLRequest()

        return try await withCheckedThrowingContinuation { continuation in
            session.request(urlRequest)
                .validate()
                .response { response in
                    if let error = response.error {
                        continuation.resume(throwing: Self.mappedError(error, response: response.response, data: response.data))
                    } else {
                        continuation.resume()
                    }
                }
        }
    }

    private static func mappedError(_ error: Error, response: HTTPURLResponse?, data: Data?) -> NetworkError {
        if let statusCode = response?.statusCode,
           statusCode != 401,
           !(200...299).contains(statusCode),
           let apiError = NetworkError.fromResponseBody(data, statusCode: statusCode) {
            return apiError
        }
        return NetworkError.from(error)
    }
}

public protocol APIEndpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var parameters: [String: any Sendable]? { get }
    var encoding: ParameterEncoding { get }
}

extension APIEndpoint {
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.name)
            }
        }

        return try encoding.encode(request, with: parameters)
    }
}

