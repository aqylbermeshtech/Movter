import Foundation
import XCTest

class UserDefaultsTestCase: XCTestCase {

    private(set) var suiteName: String!
    private(set) var defaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let name = "com.nurtore.movter.tests.\(UUID().uuidString)"
        suiteName = name
        defaults = try XCTUnwrap(UserDefaults(suiteName: name))
    }

    override func tearDown() {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
        super.tearDown()
    }
}
