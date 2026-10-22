//
//  ChangeThemeUseCase.swift
//  Movter
//
//  Created by Nurtore on 22.10.2026.
//

import Foundation

protocol ChangeThemeUseCase {
    func execute(theme: AppTheme)
}

final class DefaultChangeThemeUseCase: ChangeThemeUseCase {
    private let themeManager: ThemeManager
    
    init(themeManager: ThemeManager = .shared) {
        self.themeManager = themeManager
    }
    
    func execute(theme: AppTheme) {
        themeManager.selectTheme(theme)
    }
}
