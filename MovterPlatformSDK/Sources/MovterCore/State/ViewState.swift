//
//  ViewState.swift
//  MovterPlatformSDK
//
//  Created by Nurtore on 10.10.2026.
//

import Foundation

public enum ViewState<Value>: Equatable where Value: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty(message: String)
    case failure(message: String)
    
    
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    public var value: Value? {
        if case let .loaded(val) = self { return val }
        return nil
    }
    
    public var errorMessage: String? {
        if case let .failure(msg) = self { return msg }
        return nil
    }
}
