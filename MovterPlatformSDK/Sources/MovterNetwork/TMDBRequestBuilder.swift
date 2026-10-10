//
//  TMDBRequestBuilder.swift
//  MovterNetwork
//
//  Created by Nurtore on 10.10.2026.
//

import Foundation

public enum TMDBRequestBuilder {
    private static let baseURLString = "https://api.themoviedb.org/3"

    public static func buildURL(
        path: String,
        apiKey: String,
        queryItems: [URLQueryItem] = []
    ) throws -> URL {
        guard var components = URLComponents(string: baseURLString) else {
            throw NetworkError.missingURL
        }

        let sanitizedPath = path.hasPrefix("/") ? path : "/\(path)"
        components.path += sanitizedPath

        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        items.append(contentsOf: queryItems)
        components.queryItems = items

        guard let url = components.url else {
            throw NetworkError.missingURL
        }
        return url
    }
}
