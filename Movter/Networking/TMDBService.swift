//
//  TMDBService.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import Foundation
import MovterNetwork

// MARK: - Structs
struct MovieResponse: Codable {
    let results: [Media]
    let totalPages: Int?
}

struct MediaPage {
    let items: [Media]
    let isLastPage: Bool
}

struct VideoResponse: Codable {
    let results: [Video]
}

final class TMDBService {
    static let shared = TMDBService()

    private let apiKey = TMDBService.infoPlistValue(for: "TMDB_API_KEY")

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    private static func infoPlistValue(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            assertionFailure("Missing \(key) — copy Movter/Config/Secrets.xcconfig.example to Config/Secrets.xcconfig (next to Movter.xcodeproj) and fill in real values.")
            return ""
        }
        return value
    }

    // MARK: - Core Request Execution

    func performRequest<T: Decodable>(url: URL) async throws -> T {
        let request = URLRequest(url: url)
        let (data, response) = try await networkService.plainRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = NetworkError.fromResponseBody(data, statusCode: httpResponse.statusCode) {
                throw apiError
            }
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    // MARK: - Videos

    func fetchVideo(for id: Int, type: MediaType) async throws -> String? {
        let url = try TMDBRequestBuilder.buildURL(path: "\(type.path)/\(id)/videos", apiKey: apiKey)
        let response: VideoResponse = try await performRequest(url: url)
        let trailer = response.results.first { $0.site == "YouTube" && $0.type == "Trailer" }
                   ?? response.results.first { $0.site == "YouTube" }
        return trailer?.key
    }

    func fetchVideo(for id: Int, type: MediaType, completion: @escaping (String?) -> Void) {
        Task {
            do {
                let key = try await fetchVideo(for: id, type: type)
                await MainActor.run { completion(key) }
            } catch {
                await MainActor.run { completion(nil) }
            }
        }
    }

    // MARK: - Credits

    func fetchCredits(for id: Int, type: MediaType) async throws -> MovieCredits {
        let url = try TMDBRequestBuilder.buildURL(path: "\(type.path)/\(id)/credits", apiKey: apiKey)
        return try await performRequest(url: url)
    }

    func fetchCredits(for id: Int, type: MediaType, completion: @escaping (MovieCredits?) -> Void) {
        Task {
            do {
                let credits = try await fetchCredits(for: id, type: type)
                await MainActor.run { completion(credits) }
            } catch {
                await MainActor.run { completion(nil) }
            }
        }
    }

    // MARK: - Similar / Recommendations

    func fetchSimilar(for id: Int, type: MediaType) async throws -> [Media] {
        let recURL = try TMDBRequestBuilder.buildURL(
            path: "\(type.path)/\(id)/recommendations",
            apiKey: apiKey,
            queryItems: [URLQueryItem(name: "page", value: "1")]
        )
        do {
            let recommended: MovieResponse = try await performRequest(url: recURL)
            if !recommended.results.isEmpty {
                return recommended.results
            }
        } catch {
        }

        let simURL = try TMDBRequestBuilder.buildURL(
            path: "\(type.path)/\(id)/similar",
            apiKey: apiKey,
            queryItems: [URLQueryItem(name: "page", value: "1")]
        )
        let similar: MovieResponse = try await performRequest(url: simURL)
        return similar.results
    }

    func fetchSimilar(for id: Int, type: MediaType, completion: @escaping ([Media]?) -> Void) {
        Task {
            do {
                let similar = try await fetchSimilar(for: id, type: type)
                await MainActor.run { completion(similar) }
            } catch {
                await MainActor.run { completion(nil) }
            }
        }
    }

    // MARK: - Genres

    func fetchGenres(type: MediaType) async throws -> [GenreListResponse.Genre] {
        let url = try TMDBRequestBuilder.buildURL(path: "genre/\(type.path)/list", apiKey: apiKey)
        let response: GenreListResponse = try await performRequest(url: url)
        return response.genres
    }

    func fetchGenres(type: MediaType, completion: @escaping ([GenreListResponse.Genre]?) -> Void) {
        Task {
            do {
                let genres = try await fetchGenres(type: type)
                await MainActor.run { completion(genres) }
            } catch {
                await MainActor.run { completion(nil) }
            }
        }
    }

    // MARK: - People

    func fetchPersonDetails(for id: Int) async throws -> PersonDetails {
        let url = try TMDBRequestBuilder.buildURL(path: "person/\(id)", apiKey: apiKey)
        return try await performRequest(url: url)
    }

    func fetchPersonDetails(for id: Int, completion: @escaping (PersonDetails?) -> Void) {
        Task {
            do {
                let details = try await fetchPersonDetails(for: id)
                await MainActor.run { completion(details) }
            } catch {
                await MainActor.run { completion(nil) }
            }
        }
    }

    func fetchPersonCredits(for id: Int) async throws -> [PersonCredit] {
        let url = try TMDBRequestBuilder.buildURL(path: "person/\(id)/combined_credits", apiKey: apiKey)
        let response: PersonCreditsResponse = try await performRequest(url: url)
        return response.cast
    }

    func fetchPersonCredits(for id: Int, completion: @escaping ([PersonCredit]) -> Void) {
        Task {
            do {
                let credits = try await fetchPersonCredits(for: id)
                await MainActor.run { completion(credits) }
            } catch {
                await MainActor.run { completion([]) }
            }
        }
    }

    // MARK: - Discover

    func fetchDiscover(query: DiscoverQuery, page: Int) async throws -> MediaPage {
        var queryItems = query.queryItems
        queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        let url = try TMDBRequestBuilder.buildURL(path: query.path, apiKey: apiKey, queryItems: queryItems)
        let response: MovieResponse = try await performRequest(url: url)
        return Self.page(from: response, requested: page)
    }

    func fetchDiscover(query: DiscoverQuery, page: Int, completion: @escaping (MediaPage?) -> Void) {
        Task {
            do {
                let pageResult = try await fetchDiscover(query: query, page: page)
                await MainActor.run { completion(pageResult) }
            } catch {
                await MainActor.run { completion(nil) }
            }
        }
    }

    // MARK: - Popular Movies

    func fetchPopularMovies(page: Int) async throws -> MediaPage {
        let url = try TMDBRequestBuilder.buildURL(
            path: "movie/popular",
            apiKey: apiKey,
            queryItems: [URLQueryItem(name: "page", value: "\(page)")]
        )
        let response: MovieResponse = try await performRequest(url: url)
        return Self.page(from: response, requested: page)
    }

    func fetchPopularMovies(page: Int, completion: @escaping (MediaPage?) -> Void) {
        Task {
            do {
                let pageResult = try await fetchPopularMovies(page: page)
                await MainActor.run { completion(pageResult) }
            } catch {
                await MainActor.run { completion(nil) }
            }
        }
    }

    // MARK: - Search

    func searchMovies(query: String, page: Int) async throws -> MediaPage {
        let url = try TMDBRequestBuilder.buildURL(
            path: "search/movie",
            apiKey: apiKey,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "include_adult", value: "false")
            ]
        )
        let response: MovieResponse = try await performRequest(url: url)
        return Self.page(from: response, requested: page)
    }

    func searchMovies(query: String, page: Int, completion: @escaping (MediaPage?) -> Void) {
        Task {
            do {
                let pageResult = try await searchMovies(query: query, page: page)
                await MainActor.run { completion(pageResult) }
            } catch {
                await MainActor.run { completion(nil) }
            }
        }
    }

    // MARK: - Helpers

    private static func page(from response: MovieResponse, requested: Int) -> MediaPage {
        let cap = min(response.totalPages ?? requested, 500)
        return MediaPage(items: response.results, isLastPage: requested >= cap || response.results.isEmpty)
    }
}
