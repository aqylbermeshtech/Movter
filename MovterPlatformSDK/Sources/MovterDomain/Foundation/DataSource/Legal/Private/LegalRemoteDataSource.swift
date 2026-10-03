//
//  LegalRemoteDataSource.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation
//import MentorCore
//import MentorNetwork

nonisolated public final class LegalRemoteDataSource: LegalDataSourceProtocol {
    private let networkService: NetworkServiceProtocol
    private let router = Router<LegalEndPoint>()
    
    public init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }
    
    public func getTermsURL(lang: String) async throws -> String {
        let endPoint = LegalEndPoint.getTerms(lang: lang)
        let urlRequest = try router.request(endPoint)
        let (data, response) = try await networkService.request(urlRequest)
        let strategy = DefaultParseStrategy(data, response)
        let context = ParseContext(parseStrategy: strategy)
        
        guard let result: LegalResponseDTO = try await context.process() else {
            throw NetworkError.decodingError
        }
        
        guard let url = result.data?.url else {
            throw NetworkError.decodingError
        }
        
        return url
    }
}
