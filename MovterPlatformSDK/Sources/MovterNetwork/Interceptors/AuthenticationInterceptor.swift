//
//  AuthenticationInterceptor.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Alamofire
import Foundation
//@preconcurrency import MovterCore
//@preconcurrency import MovterDomain


public final class AuthenticationInterceptor: RequestInterceptor {
    private let logger: LoggerProtocol
    
    public static let refreshThresholdSeconds: TimeInterval = 300
    
    public init(logger: LoggerProtocol) {
        self.logger = logger
    }
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest
        
        if shouldSkipAuthentication(for: urlRequest) {
            completion(.success(adaptedRequest))
            return
        }
        
        if AccessTokenStore.shared.shouldRefreshProactively(thresholdSeconds: Self.refreshThresholdSeconds) {
            refreshAccessTokenSync { [weak self] success in
                if success {
                    self?.addAuthHeaderIfNeeded(to: &adaptedRequest)
                }
                completion(.success(adaptedRequest))
            }
            return
        }
        
        addAuthHeaderIfNeeded(to: &adaptedRequest)
        completion(.success(adaptedRequest))
    }
    
    private func addAuthHeaderIfNeeded(to request: inout URLRequest) {
        if let token = AccessTokenStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.debug("Added authorization header to request")
        }
    }
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        /// One refreshed attempt per request: a request that is still refused with a fresh token
        /// would otherwise keep spending refresh tokens in a loop.
        guard request.retryCount == 0 else {
            logger.debug("Request already retried after a refresh, giving up")
            completion(.doNotRetryWithError(error))
            return
        }
        
        logger.debug("Received 401 unauthorized, attempting token refresh")
        
        // Try to refresh token without async/await to avoid compatibility issues
        refreshAccessTokenSync { [weak self] success in
            if success {
                self?.logger.debug("Token refreshed successfully, retrying request")
                completion(.retry)
            } else {
                self?.logger.debug("Token refresh failed, not retrying")
                completion(.doNotRetryWithError(AuthenticationError.tokenRefreshFailed))
            }
        }
    }
    
    private func shouldSkipAuthentication(for request: URLRequest) -> Bool {
        guard let path = request.url?.path else { return false }
        
        let authEndpoints = [
            "/api/v1/auth/email-otp/send",
            "/api/v1/auth/email-otp/verify",
            "/api/v1/auth/token/refresh"
        ]
        
        if authEndpoints.contains(path) {
            return true
        }
        
        let publicCatalogSuffixes = [
            "/v1/catalog/directions",
            "/v1/catalog/mentors",
            "/v1/skills/taxonomy"
        ]
        return publicCatalogSuffixes.contains { suffix in
            path == suffix || path.hasSuffix(suffix)
        }
    }

    private func refreshAccessTokenSync(completion: @escaping (Bool) -> Void) {
        TokenRefreshCoordinator.shared.refresh(logger: logger, completion: completion)
    }
}

public enum AuthenticationError: Error, LocalizedError {
    case tokenRefreshFailed
    case noRefreshToken

    public var errorDescription: String? {
        switch self {
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .noRefreshToken:
            return "No refresh token available"
        }
    }
}
