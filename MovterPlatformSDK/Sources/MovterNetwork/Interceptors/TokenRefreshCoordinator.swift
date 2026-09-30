//
//  TokenRefreshCoordinator.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

@preconcurrency import Alamofire
import Foundation
//@preconcurrency import MentorCore
//@preconcurrency import MentorStorage

/// A refresh token may be spent once: the backend revokes it and issues a replacement, so a
/// second request carrying the same one fails and would log the person out. The app runs two
/// Alamofire stacks, and both can meet a 401 at the same moment, so the single-flight guard
/// has to live here, above them, rather than inside one interceptor instance.
nonisolated public final class TokenRefreshCoordinator: @unchecked Sendable {
    nonisolated public static let shared = TokenRefreshCoordinator()

    private let queue = DispatchQueue(label: "com.mentor.auth.refresh")
    private nonisolated(unsafe) var isRefreshing = false
    private nonisolated(unsafe) var handlers: [(Bool) -> Void] = []

    private init() {}

    public func refresh(logger: LoggerProtocol? = nil, completion: @escaping (Bool) -> Void) {
        let logger = logger ?? DIContainer.shared.resolve(LoggerProtocol.self) ?? Logger()
        queue.async { [weak self] in
            guard let self else {
                completion(false)
                return
            }

            if self.isRefreshing {
                logger.debug("Token refresh already in progress, queueing completion handler")
                self.handlers.append(completion)
                return
            }

            guard let refreshToken = AccessTokenStore.shared.refreshToken else {
                if AccessTokenStore.shared.accessToken != nil {
                    logger.error("No refresh token available - session will be invalidated")
                    AccessTokenStore.shared.clearAndNotifySessionInvalidated()
                } else {
                    logger.debug("Guest request got 401 - failing without session invalidation")
                }
                completion(false)
                return
            }

            self.isRefreshing = true
            self.handlers.append(completion)
            let accessTokenBefore = AccessTokenStore.shared.accessToken
            logger.debug("Starting token refresh process")

            self.performRefresh(refreshToken: refreshToken, logger: logger) { [weak self] succeeded in
                self?.finish(succeeded: succeeded, accessTokenBefore: accessTokenBefore, logger: logger)
            }
        }
    }

    private func performRefresh(
        refreshToken: String,
        logger: LoggerProtocol,
        completion: @escaping (Bool) -> Void
    ) {
        let endpoint = RefreshTokenEndpoint(refreshToken: refreshToken)
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.asURLRequest()
        } catch {
            logger.error("Failed to create refresh request: \(error)")
            completion(false)
            return
        }

        AF.request(urlRequest)
            .validate()
            .responseDecodable(of: RefreshTokenResponse.self) { response in
                switch response.result {
                case .success(let tokenResponse):
                    guard tokenResponse.success, let data = tokenResponse.data else {
                        logger.error("Token refresh failed - server response: \(tokenResponse.message ?? "Unknown error")")
                        completion(false)
                        return
                    }
                    /// The replacement refresh token is stored with the access token: the one
                    /// just used is already revoked on the backend.
                    AccessTokenStore.shared.saveTokens(
                        accessToken: data.accessToken,
                        refreshToken: data.refreshToken,
                        expiresIn: data.expiresIn
                    )
                    logger.debug("Tokens refreshed successfully")
                    completion(true)

                case .failure(let error):
                    logger.error("Failed to refresh token: \(error.localizedDescription)")
                    if let httpResponse = response.response, httpResponse.statusCode == 401 {
                        logger.error("Refresh token is invalid or expired (401)")
                    }
                    completion(false)
                }
            }
    }

    private func finish(succeeded: Bool, accessTokenBefore: String?, logger: LoggerProtocol) {
        queue.async { [weak self] in
            guard let self else { return }
            var outcome = succeeded
            if !outcome, let current = AccessTokenStore.shared.accessToken, current != accessTokenBefore {
                /// Someone renewed the session while this attempt was in flight, so the spent
                /// token is not a reason to sign the person out.
                logger.debug("Refresh failed but the session was renewed meanwhile, continuing")
                outcome = true
            }
            if !outcome {
                AccessTokenStore.shared.clearAndNotifySessionInvalidated()
            }
            self.isRefreshing = false
            let pending = self.handlers
            self.handlers.removeAll()
            DispatchQueue.main.async {
                pending.forEach { $0(outcome) }
            }
        }
    }
}

nonisolated private struct RefreshTokenEndpoint: APIEndpoint {
    
    let refreshToken: String

    var baseURL: URL {
        NetworkConfiguration.shared.baseURL
    }

    var path: String {
        "/v1/auth/token/refresh"
    }

    var method: HTTPMethod {
        .post
    }

    var headers: HTTPHeaders? {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    var parameters: [String: Any]? {
        ["refresh_token": refreshToken]
    }

    var encoding: ParameterEncoding {
        JSONEncoding.default
    }
}

