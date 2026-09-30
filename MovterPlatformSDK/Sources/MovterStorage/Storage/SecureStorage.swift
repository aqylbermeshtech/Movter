//
//  SecureStorage.swift
//  Movter
//
//  Created by Nurtore on 28.09.2026.
//

import Foundation
import Security

nonisolated public protocol StorageProtocol: Sendable {
    func saveSecure(_ data: Data, for key: String) throws
    func loadSecure(for key: String) throws -> Data?
    func deleteSecure(for key: String) throws

    // UserDefaults methods for simple data
    func save(_ value: Any, for key: String)
    func load(for key: String) -> Any?
    func delete(for key: String)
    func exists(key: String) -> Bool

    // Convenience methods
    func saveString(_ string: String, for key: String) throws
    func loadString(for key: String) throws -> String?
    func saveCodable<T: Codable>(_ object: T, for key: String) throws
    func loadCodable<T: Codable>(_ type: T.Type, for key: String) throws -> T?
}

nonisolated public final class SecureStorage: StorageProtocol, @unchecked Sendable {
    private let userDefaults = UserDefaults.standard

    private var keychainService: String {
        #if DEBUG
        return "com.mentor.app.debug"
        #else
        return "com.mentor.app"
        #endif
    }

    public init() {}

    // MARK: - Keychain (for sensitive data like tokens)

    public func saveSecure(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw StorageError.keychainError(status)
        }
    }

    public func loadSecure(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw StorageError.keychainError(status)
        }

        return result as? Data
    }

    public func deleteSecure(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StorageError.keychainError(status)
        }
    }

    // MARK: - UserDefaults (for simple data)

    public func save(_ value: Any, for key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func load(for key: String) -> Any? {
        return userDefaults.object(forKey: key)
    }

    public func delete(for key: String) {
        userDefaults.removeObject(forKey: key)
    }

    public func exists(key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }

    // MARK: - Convenience methods

    public func saveString(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw StorageError.invalidData
        }
        try saveSecure(data, for: key)
    }

    public func loadString(for key: String) throws -> String? {
        guard let data = try loadSecure(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func saveCodable<T: Codable>(_ object: T, for key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try saveSecure(data, for: key)
    }

    public func loadCodable<T: Codable>(_ type: T.Type, for key: String) throws -> T? {
        guard let data = try loadSecure(for: key) else { return nil }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

nonisolated public enum StorageError: Error, LocalizedError {
    case keychainError(OSStatus)
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error with status: \(status)"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}
