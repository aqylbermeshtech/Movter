//
//  Foundation+Extensions.swift
//  Movter
//
//  Created by Nurtore on 22.09.2026.
//

import Foundation

// MARK: - String Extensions
public extension String {
    var isNotEmpty: Bool {
        return !isEmpty
    }

    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }
}

// MARK: - StringProtocol + Digits
public extension StringProtocol {
    /// Только цифры из строки. `"abc123def45" → "12345"`
    var digitsOnly: String {
        String(filter(\.isNumber))
    }

    /// Только цифры, не длиннее `maxLength`. `"abc123def45".digits(max: 3) → "123"`
    func digits(max maxLength: Int) -> String {
        String(filter(\.isNumber).prefix(maxLength))
    }
}

// MARK: - Optional Extensions
public extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }

    var orEmpty: String {
        return self ?? ""
    }
}

// MARK: - Collection Extensions
public extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

// MARK: - URL Extensions
public extension URL {
    func appendingQueryItem(name: String, value: String?) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        components.queryItems = queryItems

        return components.url ?? self
    }
}

// MARK: - Date Extensions
private let apiDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

public extension Date {
    /// Формат yyyy-MM-dd для API-запросов
    func toAPIDateString() -> String {
        apiDateFormatter.string(from: self)
    }

    /// Парсинг строки yyyy-MM-dd в Date
    static func fromAPIDateString(_ string: String) -> Date? {
        apiDateFormatter.date(from: string)
    }
}

// MARK: - Data Extensions
public extension Data {
    func toPrettyJSON() -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}

