//
//  LanguageManager.swift
//  Movter
//
//  Created by Nurtore on 04.10.2026.
//

import Foundation
import SwiftUI
import ObjectiveC
import Combine

final class LanguageManager: ObservableObject {
    let objectWillChange: ObservableObjectPublisher
    
    @Published var currentLanguage: Language {
        didSet {
            saveAndApply(currentLanguage.code)
        }
    }

    static let shared = LanguageManager()
    private let languageKey = "selectedLanguage"

    init() {
        let savedCode = UserDefaults.standard.string(forKey: languageKey)
            ?? Locale.current.language.languageCode?.identifier
            ?? "ru"
        self.currentLanguage = Language.getLanguage(code: savedCode)
        Bundle.setMentorLanguage(savedCode)
    }

    func setLanguage(_ language: Language) {
        self.currentLanguage = language
    }

    /// Язык для вебвью (поддерживаются только ru/kk): kk → "kk", остальное → "ru".
    var webLanguageCode: String {
        currentLanguage.code == "kk" ? "kk" : "ru"
    }

    private func saveAndApply(_ code: String) {
        UserDefaults.standard.set(code, forKey: languageKey)
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        Bundle.setMentorLanguage(code)
    }
}

private var mentorBundleKey: UInt8 = 0

private final class MentorLocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let path = objc_getAssociatedObject(self, &mentorBundleKey) as? String,
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setMentorLanguage(_ code: String) {
        if !(Bundle.main is MentorLocalizedBundle) {
            object_setClass(Bundle.main, MentorLocalizedBundle.self)
        }
        let path = Bundle.main.path(forResource: code, ofType: "lproj")
        objc_setAssociatedObject(
            Bundle.main,
            &mentorBundleKey,
            path,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

