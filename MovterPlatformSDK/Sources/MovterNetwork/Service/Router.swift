//
//  Router.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

nonisolated public class Router<EndPoint: EndPointType> {
    
    public init() {}
    
    public func request(_ route: EndPoint) throws -> URLRequest {
        var url = route.baseURL.appendingPathComponent(route.path)
        
        // Handle full URLs in path
        if route.path.contains("http") {
            url = URL(string: route.path) ?? route.baseURL.appendingPathComponent(route.path)
        }
        
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 30.0
        )
        
        request.httpMethod = route.httpMethod.rawValue
        
        // Set default headers
        if let headers = route.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Configure task
        switch route.task {
        case .request:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
        case let .requestParameters(bodyParameters, bodyEncoding, urlParameters):
            try bodyEncoding.encode(
                urlRequest: &request,
                bodyParameters: bodyParameters,
                urlParameters: urlParameters
            )
            
        case let .requestParametersAndHeaders(bodyParameters, bodyEncoding, urlParameters, additionalHeaders):
            if let headers = additionalHeaders {
                for (key, value) in headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
            try bodyEncoding.encode(
                urlRequest: &request,
                bodyParameters: bodyParameters,
                urlParameters: urlParameters
            )
            
        case let .requestEncodable(requestModel):
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestModel)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
}

