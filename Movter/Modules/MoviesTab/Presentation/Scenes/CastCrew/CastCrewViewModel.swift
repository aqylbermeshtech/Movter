//
//  CastCrewViewModel.swift
//  Movter
//
//  Created by Nurtore on 08.09.2026.
//

import Foundation

struct CreditRow {
    let personID: Int
    let name: String
    let role: String
    let profileURL: URL?
}

struct CreditSection {
    let title: String
    let rows: [CreditRow]
}

@MainActor
final class CastCrewViewModel {
    let mediaTitle: String
    private(set) var sections: [CreditSection] = []
    private weak var coordinator: MoviesCoordinator?
    private static let departmentOrder = [
        "Directing", "Writing", "Production", "Camera", "Editing",
        "Sound", "Art", "Costume & Make-Up", "Visual Effects", "Lighting"
    ]

    init(
        mediaTitle: String,
        cast: [Actor],
        crew: [CrewMember],
        coordinator: MoviesCoordinator? = nil
    ) {
        self.mediaTitle = mediaTitle
        self.coordinator = coordinator
        sections = Self.makeSections(cast: cast, crew: crew)
    }

    var isEmpty: Bool { sections.isEmpty }

    func numberOfRows(in section: Int) -> Int {
        sections[safe: section]?.rows.count ?? 0
    }

    func row(inSection section: Int, at index: Int) -> CreditRow? {
        sections[safe: section]?.rows[safe: index]
    }

    func title(forSection section: Int) -> String? {
        sections[safe: section]?.title
    }

    func showActorDetails(actorId: Int, name: String) {
        coordinator?.showActorDetails(actorId: actorId, name: name)
    }

    // MARK: - Building

    private static func makeSections(cast: [Actor], crew: [CrewMember]) -> [CreditSection] {
        var sections: [CreditSection] = []

        if !cast.isEmpty {
            let rows = cast.map {
                CreditRow(
                    personID: $0.id,
                    name: $0.name,
                    role: $0.character.trimmingCharacters(in: .whitespacesAndNewlines),
                    profileURL: $0.profileURL
                )
            }
            sections.append(CreditSection(title: "Cast", rows: rows))
        }

        sections.append(contentsOf: crewSections(from: crew))
        return sections
    }

    private static func crewSections(from crew: [CrewMember]) -> [CreditSection] {
        var departments: [String] = []
        var rowsByDepartment: [String: [CreditRow]] = [:]
        var indexOfPerson: [String: [Int: Int]] = [:]

        for member in crew {
            let department = member.department?.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = (department?.isEmpty == false ? department! : "Crew")
            let job = member.job?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if rowsByDepartment[name] == nil {
                departments.append(name)
                rowsByDepartment[name] = []
                indexOfPerson[name] = [:]
            }

            if let existing = indexOfPerson[name]?[member.id] {
                guard !job.isEmpty else { continue }
                let row = rowsByDepartment[name]![existing]
                let merged = row.role.isEmpty ? job : "\(row.role), \(job)"
                rowsByDepartment[name]![existing] = CreditRow(
                    personID: row.personID,
                    name: row.name,
                    role: merged,
                    profileURL: row.profileURL ?? member.profileURL
                )
            } else {
                indexOfPerson[name]?[member.id] = rowsByDepartment[name]!.count
                rowsByDepartment[name]!.append(
                    CreditRow(
                        personID: member.id,
                        name: member.name,
                        role: job,
                        profileURL: member.profileURL
                    )
                )
            }
        }

        return departments
            .sorted { rank(of: $0, in: departments) < rank(of: $1, in: departments) }
            .compactMap { department in
                guard let rows = rowsByDepartment[department], !rows.isEmpty else { return nil }
                return CreditSection(title: department, rows: rows)
            }
    }

    private static func rank(of department: String, in order: [String]) -> Int {
        if let index = departmentOrder.firstIndex(of: department) { return index }
        return departmentOrder.count + (order.firstIndex(of: department) ?? 0)
    }
}

