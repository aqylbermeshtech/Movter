//
//  RequestTask.swift
//  Movter
//
//  Created by Nurtore on 29.09.2026.
//

import Foundation

public typealias RequestParameters = [String: Any]
public typealias RequestHeaders = [String: String]

/// Custom HTTP task enum for Clean Architecture
/// Note: Named RequestTask to avoid potential conflicts
public enum RequestTask {
    /// A request with no additional data
    case request
    
    /// A request with body and/or URL parameters
    case requestParameters(
        bodyParameters: RequestParameters?,
        bodyEncoding: RequestEncoding,
        urlParameters: RequestParameters?
    )
    
    /// A request with parameters and additional headers
    case requestParametersAndHeaders(
        bodyParameters: RequestParameters?,
        bodyEncoding: RequestEncoding,
        urlParameters: RequestParameters?,
        additionalHeaders: RequestHeaders?
    )
    
    /// A request with Encodable body
    case requestEncodable(requestModel: Encodable)
}

