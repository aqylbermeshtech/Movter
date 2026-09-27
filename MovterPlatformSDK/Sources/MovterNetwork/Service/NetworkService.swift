//
//  NetworkService.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Alamofire
import Foundation
//import MentorCore
//import MentorStorage

public protocol NetworkServiceProtocol {
    /// Performs an authenticated request through Alamofire interceptors (auth, retry, logging).
    func request(_ request: URLRequest) async throws -> (Data, URLResponse)
    /// Performs a plain, unauthenticated request via URLSession — no interceptors, no auth headers.
    func plainRequest(_ request: URLRequest) async throws -> (Data, URLResponse)
}

public final class NetworkService: NetworkServiceProtocol {
    public static let shared = NetworkService()
    
    private let session: Session
    private let logger: LoggerProtocol
    
    private init() {
        let resolvedLogger = DIContainer.shared.resolve(LoggerProtocol.self) ?? Logger()
        self.logger = resolvedLogger

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.urlCache = URLCache.shared
        configuration.requestCachePolicy = .useProtocolCachePolicy

        let authInterceptor = AuthenticationInterceptor(logger: resolvedLogger)
        let loggingInterceptor = LoggingInterceptor(logger: resolvedLogger)
        let errorInterceptor = ErrorHandlingInterceptor(logger: resolvedLogger)

        self.session = Session(
            configuration: configuration,
            interceptor: Interceptor(
                adapters: [authInterceptor, errorInterceptor],
                retriers: [authInterceptor, errorInterceptor]
            ),
            eventMonitors: [loggingInterceptor]
        )
    }

    // MARK: - Plain (unauthenticated) session

    private static let plainSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: config)
    }()

    // MARK: - Authenticated request (Alamofire)

    public func request(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(request)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        if let httpResponse = response.response {
                            continuation.resume(returning: (data, httpResponse))
                        } else {
                            continuation.resume(throwing: NetworkError.invalidResponse)
                        }
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode,
                           statusCode != 401,
                           let apiError = NetworkError.fromResponseBody(response.data, statusCode: statusCode) {
                            continuation.resume(throwing: apiError)
                        } else {
                            continuation.resume(throwing: NetworkError.from(error))
                        }
                    }
                }
        }
    }

    // MARK: - Plain request (no auth, no interceptors)

    public func plainRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = try await Self.plainSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.serverError(http.statusCode)
        }
        return (data, http)
    }
}

