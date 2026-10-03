//
//  DateFormatters+Extensions.swift
//  Movter
//
//  Created by Nurtore on 22.09.2026.
//

import Foundation

public final class DateFormatterProvider {
    public static let shared = DateFormatterProvider()

    private init() {}

    public let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    public let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    public let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    public let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    public let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

public extension Date {
    func toISO8601String() -> String {
        return DateFormatterProvider.shared.iso8601.string(from: self)
    }

    func toShortDateString() -> String {
        return DateFormatterProvider.shared.shortDate.string(from: self)
    }

    func toLongDateString() -> String {
        return DateFormatterProvider.shared.longDate.string(from: self)
    }

    func toTimeString() -> String {
        return DateFormatterProvider.shared.timeOnly.string(from: self)
    }

    func toDateTimeString() -> String {
        return DateFormatterProvider.shared.dateTime.string(from: self)
    }
}

public extension String {
    func toDateFromISO8601() -> Date? {
        return DateFormatterProvider.shared.iso8601.date(from: self)
    }
}
