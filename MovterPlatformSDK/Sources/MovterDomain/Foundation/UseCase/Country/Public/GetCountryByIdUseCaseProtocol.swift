//
//  GetCountryByIdUseCaseProtocol.swift
//  Movter
//
//  Created by Nurtore on 02.10.2026.
//

import Foundation
//import MentorNetwork

public protocol GetCountryByIdUseCaseProtocol {
    func execute(id: String) -> CountryDTO?
}

