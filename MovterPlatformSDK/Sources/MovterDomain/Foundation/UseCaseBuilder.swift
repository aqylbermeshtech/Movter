//
//  UseCaseBuilder.swift
//  MentorDomain
//
//  Единый builder для создания всех UseCases.
//  Собирает полную цепочку зависимостей: DataSource → Repository → UseCase
//  Возвращает ТОЛЬКО готовые UseCases.
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
