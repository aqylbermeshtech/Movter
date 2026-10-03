//
//  TMDBService.swift
//  Movter
//
//  Created by Nurtore on 24.03.2026.
//

import Foundation

//MARK: - Struct
struct MovieResponse: Codable {
    let results: [Media]
    /// TMDB caps paging at 500; without this the grid kept requesting pages forever.
    let totalPages: Int?
}

struct MediaPage {
    let items: [Media]
    let isLastPage: Bool
}

struct VideoResponse: Codable {
    let results: [Video]
}

/// Uses `NetworkService.shared.plainRequest(_:)` under the hood — the SDK's unified
/// network layer — for all HTTP calls. No separate URLSession here.
final class TMDBService {
    static let shared = TMDBService()
    private let baseURL = "https://api.themoviedb.org/3"

    // Injected at build time from Config/Secrets.xcconfig (gitignored); see
    // Movter/Config/Secrets.xcconfig.example.
    private let apiKey = TMDBService.infoPlistValue(for: "TMDB_API_KEY")

    /// The SDK's unified network service handles the actual HTTP calls.
    private let networkService: NetworkServiceProtocol

    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    private static func infoPlistValue(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            assertionFailure("Missing \(key) — copy Movter/Config/Secrets.xcconfig.example to Config/Secrets.xcconfig (next to Movter.xcodeproj) and fill in real values.")
            return ""
        }
        return value
    }
    
    private func performRequest<T: Decodable>(urlString: String, completion: @escaping (T?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        Task {
            do {
                let request = URLRequest(url: url)
                let (data, _) = try await networkService.plainRequest(request)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(T.self, from: data)
                await MainActor.run { completion(result) }
            } catch {
                print("Network/decoding error: \(error)")
                await MainActor.run { completion(nil) }
            }
        }
    }

    func fetchVideo(for id: Int, type: MediaType, completion: @escaping (String?) -> Void) {
        let urlString = "\(baseURL)/\(type.path)/\(id)/videos?api_key=\(apiKey)"
        performRequest(urlString: urlString) { (result: VideoResponse?) in
            // Prefer an actual trailer, then any YouTube clip — TMDB also returns
            // teasers, featurettes and clips under the same endpoint.
            let trailer = result?.results.first { $0.site == "YouTube" && $0.type == "Trailer" }
                       ?? result?.results.first { $0.site == "YouTube" }
            completion(trailer?.key)
        }
    }
    
    /// Cast and crew arrive on the same call, so this hands back the whole payload
    /// rather than the cast alone — the cast and crew screen needs both halves.
    func fetchCredits(for id: Int, type: MediaType, completion: @escaping (MovieCredits?) -> Void) {
        let urlString = "\(baseURL)/\(type.path)/\(id)/credits?api_key=\(apiKey)"
        performRequest(urlString: urlString, completion: completion)
    }
    
    /// What to watch after this one. TMDB's recommendations come from what audiences
    /// actually went on to watch, so they lead; `similar` — matched on genre and
    /// keywords — is the fallback for titles nobody has recommendations for yet.
    ///
    /// Nil only when both requests fail. An empty list is a real answer.
    func fetchSimilar(for id: Int, type: MediaType, completion: @escaping ([Media]?) -> Void) {
        performRequest(urlString: relatedTitlesURL("recommendations", for: id, type: type)) { (recommended: MovieResponse?) in
            if let results = recommended?.results, !results.isEmpty {
                completion(results)
                return
            }
            self.performRequest(urlString: self.relatedTitlesURL("similar", for: id, type: type)) { (similar: MovieResponse?) in
                guard let results = similar?.results else {
                    completion(recommended == nil ? nil : [])
                    return
                }
                completion(results)
            }
        }
    }

    private func relatedTitlesURL(_ path: String, for id: Int, type: MediaType) -> String {
        "\(baseURL)/\(type.path)/\(id)/\(path)?api_key=\(apiKey)&language=en-US&page=1"
    }

    func fetchGenres(type: MediaType, completion: @escaping ([GenreListResponse.Genre]?) -> Void) {
        let urlString = "\(baseURL)/genre/\(type.path)/list?api_key=\(apiKey)&language=en-US"
        performRequest(urlString: urlString) { (result: GenreListResponse?) in
            completion(result?.genres)
        }
    }

    func fetchPersonDetails(for id: Int, completion: @escaping (PersonDetails?) -> Void) {
        let urlString = "\(baseURL)/person/\(id)?api_key=\(apiKey)&language=en-US"
        performRequest(urlString: urlString, completion: completion)
    }

    func fetchPersonCredits(for id: Int, completion: @escaping ([PersonCredit]) -> Void) {
        let urlString = "\(baseURL)/person/\(id)/combined_credits?api_key=\(apiKey)&language=en-US"
        performRequest(urlString: urlString) { (result: PersonCreditsResponse?) in
            completion(result?.cast ?? [])
        }
    }

    func fetchDiscover(query: DiscoverQuery, page: Int, completion: @escaping (MediaPage?) -> Void) {
        var components = URLComponents(string: baseURL + query.path)
        components?.queryItems = query.queryItems + [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        guard let urlString = components?.url?.absoluteString else {
            completion(nil)
            return
        }
        performRequest(urlString: urlString) { (result: MovieResponse?) in
            completion(result.map { Self.page(from: $0, requested: page) })
        }
    }

    /// TMDB refuses pages past 500 regardless of `total_pages`.
    private static func page(from response: MovieResponse, requested: Int) -> MediaPage {
        let cap = min(response.totalPages ?? requested, 500)
        return MediaPage(items: response.results, isLastPage: requested >= cap || response.results.isEmpty)
    }

    /// Feeds the swipe deck. Plain `/movie/popular`, paginated the same way as
    /// `fetchDiscover`/`searchMovies`.
    func fetchPopularMovies(page: Int, completion: @escaping (MediaPage?) -> Void) {
        let urlString = "\(baseURL)/movie/popular?page=\(page)&api_key=\(apiKey)&language=en-US"
        performRequest(urlString: urlString) { (result: MovieResponse?) in
            completion(result.map { Self.page(from: $0, requested: page) })
        }
    }

    func searchMovies(query: String, page: Int, completion: @escaping (MediaPage?) -> Void) {
        var components = URLComponents(string: baseURL + "/search/movie")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        guard let urlString = components?.url?.absoluteString else {
            completion(nil)
            return
        }
        performRequest(urlString: urlString) { (result: MovieResponse?) in
            completion(result.map { Self.page(from: $0, requested: page) })
        }
    }

}
