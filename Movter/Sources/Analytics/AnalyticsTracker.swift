//
//  AnalyticsTracker.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
//import MentorNetwork

enum AnalyticsTracker {
    private enum Constants {
        static let retryCount: Int = 2
        static let retryDelayNanoseconds: UInt64 = 2_000_000_000
    }

    static func track(_ event: AnalyticsEvent) {
        let request = AnalyticsEnvelope.make(name: event.name, payload: event.payload)
        Task.detached(priority: .background) {
            await send(request)
        }
    }

    /// Retries reuse the very same request, so `event_id` stays stable and the
    /// backend does not register a second occurrence of one logical event.
    private static func send(_ request: AnalyticsEventRequestDTO) async {
        for attempt in 0...Constants.retryCount {
            do {
                let urlRequest = try Router<AnalyticsEndPoint>().request(.sendEvent(request: request))
                _ = try await NetworkService.shared.request(urlRequest)
                #if DEBUG
                print("[Analytics] sent \(request.event)")
                #endif
                return
            } catch {
                guard attempt < Constants.retryCount, isRetryable(error) else {
                    #if DEBUG
                    print("[Analytics] failed \(request.event): \(error.localizedDescription)")
                    #endif
                    return
                }
                try? await Task.sleep(nanoseconds: Constants.retryDelayNanoseconds)
            }
        }
    }

    private static func isRetryable(_ error: Error) -> Bool {
        let networkError = NetworkError.from(error)
        switch networkError {
        case .noInternetConnection, .timeoutError, .serverError:
            return true
        default:
            return false
        }
    }
}
