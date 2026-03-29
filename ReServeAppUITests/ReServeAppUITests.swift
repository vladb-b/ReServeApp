//
//  ReServeAppUITests.swift
//  ReServeAppUITests
//
//  Created by VI on 13/02/2026.
//

// For detailed testing guidelines, please refer to TESTING.md in the root directory.

import XCTest

final class ReServeAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // Set device orientation to portrait before launching the app to ensure consistent UI state.
        // This is crucial for reliable UI tests.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // Maestro: Start of testExample
        
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        // Maestro: End of testExample
    }

    @MainActor
    func testLaunchPerformance() throws {
        // Maestro: Start of testLaunchPerformance
        
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIDevice.shared.orientation = .portrait
            XCUIApplication().launch()
        }
        
        // Maestro: End of testLaunchPerformance
    }
}
