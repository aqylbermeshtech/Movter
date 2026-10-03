//
//  DefaultParseStrategy.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation

nonisolated public class DefaultParseStrategy: ParseStrategy {
    public var data: Data?
    public var response: URLResponse?
    
    public required init(_ data: Data?, _ response: URLResponse?) {
        self.data = data
        self.response = response
    }
    
    public func parse<T: Codable>() async throws -> T? {
        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(response.statusCode) else {
            if response.statusCode != 401,
               let apiError = NetworkError.fromResponseBody(data, statusCode: response.statusCode) {
                throw apiError
            }

            switch response.statusCode {
            case 401:
                throw NetworkError.unauthorized
            case 403:
                throw NetworkError.forbidden
            case 404:
                throw NetworkError.notFound
            default:
                throw NetworkError.serverError(response.statusCode)
            }
        }
        
        guard let responseData = data else {
            throw NetworkError.noData
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: responseData)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}

