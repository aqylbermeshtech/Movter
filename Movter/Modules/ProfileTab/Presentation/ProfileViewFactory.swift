//
//  ProfileViewFactory.swift
//  Movter
//
//  Created by Nurtore on 21.10.2026.
//

import UIKit

enum ProfileViewFactory {

    @MainActor
    static func make() -> UIViewController {
        // 1. Data Source (Firebase)
        let dataSource = FirebaseAuthProfileDataSource()

        // 2. Repository (Converts DTO to Domain UserProfile)
        let repository = DefaultProfileRepository(dataSource: dataSource)

        // 3. Use Case
        let useCase = DefaultGetProfileUseCase(repository: repository)

        // 4. Presentation
        let viewModel = ProfileViewModel2(getProfileUseCase: useCase)

        return ProfileViewController2(viewModel: viewModel)
    }
}

