//
//  Country.swift
//  Movter
//
//  Created by Nurtore on 19.09.2026.
//

import Foundation
//import MovterNetwork

struct Country: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let dialCode: String
    let flag: String
    
    var firstLetter: String {
        String(name.prefix(1).uppercased())
    }
    
    init(id: String, name: String, dialCode: String, flag: String) {
        self.id = id
        self.name = name
        self.dialCode = dialCode
        self.flag = flag
    }
    
    init(dto: CountryDTO) {
        self.id = dto.id
        self.name = dto.name
        self.dialCode = dto.dialCode
        self.flag = dto.flag
    }
    
    static func < (lhs: Country, rhs: Country) -> Bool {
        lhs.name < rhs.name
    }
}
