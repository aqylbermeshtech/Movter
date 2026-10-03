//
//  RequestEncoding.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

/// Defines how request parameters are encoded into the HTTP body or URL.
public enum RequestEncoding {
    /// Encodes parameters as URL query string.
    case urlEncoding
    /// Encodes parameters as JSON body.
    case jsonEncoding

    /// Applies the encoding to the given URLRequest.
    public func encode(
        urlRequest: inout URLRequest,
        bodyParameters: [String: Any]?,
        urlParameters: [String: Any]?
    ) throws {
        switch self {
        case .urlEncoding:
            if let urlParams = urlParameters,
               let url = urlRequest.url,
               var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                components.queryItems = urlParams.map {
                    URLQueryItem(name: $0.key, value: "\($0.value)")
                }
                urlRequest.url = components.url
            }
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8",
                                   forHTTPHeaderField: "Content-Type")
            }

        case .jsonEncoding:
            if let bodyParams = bodyParameters {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: bodyParams)
            }
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            // Also handle URL parameters when using JSON body encoding
            if let urlParams = urlParameters,
               let url = urlRequest.url,
               var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                components.queryItems = urlParams.map {
                    URLQueryItem(name: $0.key, value: "\($0.value)")
                }
                urlRequest.url = components.url
            }
        }
    }
}
