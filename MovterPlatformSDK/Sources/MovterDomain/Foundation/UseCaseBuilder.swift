//
//  UseCaseBuilder.swift
//  MentorDomain
//

import Foundation
public final class UseCaseBuilder {
    
    public static let shared = UseCaseBuilder()
    
    private let bundle: Bundle
    
    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    // Future TMDb Movie, Watchlist, and Review use case factory methods will be added here.
}
