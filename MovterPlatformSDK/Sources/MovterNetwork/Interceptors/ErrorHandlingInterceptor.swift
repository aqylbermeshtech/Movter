//
//  ErrorHandlingInterceptor.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

@preconcurrency import Alamofire
import Foundation
//@preconcurrency import MentorCore

nonisolated public final class ErrorHandlingInterceptor: RequestInterceptor {
    private let logger: LoggerProtocol

    public init(logger: LoggerProtocol) {
        self.logger = logger
    }

    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        // Add common error handling headers
        var adaptedRequest = urlRequest

        // Add request ID for tracing
        let requestId = UUID().uuidString
        adaptedRequest.setValue(requestId, forHTTPHeaderField: "X-Request-ID")

        // Add app version for debugging
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            adaptedRequest.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        }

        completion(.success(adaptedRequest))
    }

    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse else {
            completion(.doNotRetryWithError(error))
            return
        }

        let statusCode = response.statusCode
        let requestId = request.request?.value(forHTTPHeaderField: "X-Request-ID") ?? "unknown"

        logger.debug("Handling error for request \(requestId), status: \(statusCode)")

        // Handle specific error cases
        switch statusCode {
        case 429: // Rate Limited
            handleRateLimitError(request: request, completion: completion)

        case 500...599: // Server Errors
            handleServerError(request: request, statusCode: statusCode, completion: completion)

        case 408: // Request Timeout
            handleTimeoutError(request: request, completion: completion)

        default:
            completion(.doNotRetryWithError(error))
        }
    }

    private func handleRateLimitError(request: Request, completion: @escaping (RetryResult) -> Void) {
        // Check if we have Retry-After header
        if let response = request.task?.response as? HTTPURLResponse,
           let retryAfterString = response.allHeaderFields["Retry-After"] as? String,
           let retryAfter = TimeInterval(retryAfterString) {
            logger.debug("Rate limited, retrying after \(retryAfter) seconds")
            completion(.retryWithDelay(retryAfter))
        } else {
            // Default backoff for rate limiting
            logger.debug("Rate limited, retrying after 5 seconds")
            completion(.retryWithDelay(5.0))
        }
    }

    private func handleServerError(request: Request, statusCode: Int, completion: @escaping (RetryResult) -> Void) {
        // Only retry on 5xx errors, and only a few times
        let retryCount = request.retryCount
        let maxRetries = 3

        if retryCount < maxRetries {
            let delay = min(pow(2.0, Double(retryCount)), 10.0) // Exponential backoff, max 10s
            logger.debug("Server error \(statusCode), retry \(retryCount + 1)/\(maxRetries) after \(delay)s")
            completion(.retryWithDelay(delay))
        } else {
            logger.debug("Server error \(statusCode), max retries reached")
            completion(.doNotRetryWithError(NetworkError.serverError(statusCode)))
        }
    }

    private func handleTimeoutError(request: Request, completion: @escaping (RetryResult) -> Void) {
        let retryCount = request.retryCount
        let maxRetries = 2

        if retryCount < maxRetries {
            let delay = Double(retryCount + 1) * 2.0 // 2s, 4s
            logger.debug("Request timeout, retry \(retryCount + 1)/\(maxRetries) after \(delay)s")
            completion(.retryWithDelay(delay))
        } else {
            logger.debug("Request timeout, max retries reached")
            completion(.doNotRetryWithError(NetworkError.timeoutError))
        }
    }
}

