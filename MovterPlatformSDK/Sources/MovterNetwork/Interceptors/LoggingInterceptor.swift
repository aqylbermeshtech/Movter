//
//  LoggingInterceptor.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Alamofire
import Foundation
//@preconcurrency import MentorCore

public final class LoggingInterceptor: EventMonitor {
    private let logger: LoggerProtocol

    public init(logger: LoggerProtocol) {
        self.logger = logger
    }

    private func mirrorDebugLog(_ message: String) {
        #if DEBUG
        NetworkDebugLogStore.shared.append(message)
        #endif
    }

    public func requestDidResume(_ request: Request) {
        let httpRequest = request.request
        let method = httpRequest?.httpMethod ?? "Unknown"
        let url = httpRequest?.url?.absoluteString ?? "Unknown URL"

        let line = "HTTP \(method) \(url)"
        logger.debug(line)
        mirrorDebugLog(line)

        // Log headers in debug mode
        #if DEBUG
        if let headers = httpRequest?.allHTTPHeaderFields, !headers.isEmpty {
            logger.debug("Headers:")
            mirrorDebugLog("Headers:")
            for (key, value) in headers {
                // Hide sensitive headers
                if key.lowercased() == "authorization" {
                    let h = "   \(key): Bearer ***"
                    logger.debug(h)
                    mirrorDebugLog(h)
                } else {
                    let h = "   \(key): \(value)"
                    logger.debug(h)
                    mirrorDebugLog(h)
                }
            }
        }

        // Log body for POST/PUT requests
        if let httpBody = httpRequest?.httpBody,
           let method = httpRequest?.httpMethod,
           ["POST", "PUT", "PATCH"].contains(method) {
            if let bodyString = String(data: httpBody, encoding: .utf8) {
                let b = "Body: \(bodyString)"
                logger.debug(b)
                mirrorDebugLog(b)
            }
        }
        #endif
    }

    public func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        let statusCode = response.response?.statusCode ?? 0
        let url = request.request?.url?.absoluteString ?? "Unknown URL"
        let duration = response.metrics?.taskInterval.duration ?? 0

        let statusTag = statusLabel(for: statusCode)

        let summary = "\(statusTag) \(statusCode) \(url) (\(String(format: "%.2f", duration))s)"
        logger.debug(summary)
        mirrorDebugLog(summary)

        // Log response data in debug mode
        #if DEBUG
        if let data = response.data,
           let responseString = String(data: data, encoding: .utf8) {
            let r = "Response: \(responseString)"
            logger.debug(r)
            mirrorDebugLog(r)
        }
        #endif

        // Log errors
        if let error = response.error {
            let e = "Request failed: \(error.localizedDescription)"
            logger.error(e)
            mirrorDebugLog("ERROR \(e)")
        }
    }

    public func request(_ request: Request, didFailTask task: URLSessionTask, earlyWithError error: AFError) {
        let url = request.request?.url?.absoluteString ?? "Unknown URL"
        let e = "Request failed early: \(url) - \(error.localizedDescription)"
        logger.error(e)
        #if DEBUG
        mirrorDebugLog("ERROR \(e)")
        #endif
    }

    private func statusLabel(for statusCode: Int) -> String {
        switch statusCode {
        case 200...299:
            return "[2xx]"
        case 300...399:
            return "[3xx]"
        case 400...499:
            return "[4xx]"
        case 500...599:
            return "[5xx]"
        default:
            return "[?]"
        }
    }
}

