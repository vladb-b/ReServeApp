# UI Testing in This Project (2026)

## Where Are My Tests?
- All UI tests are in the `ReServeAppUITests` folder (or the similarly named UI test target folder).
- Use the new Swift Testing files (e.g., `BookingFlowUITests.swift`) for all modern tests.
- Legacy XCTest files are: `ReServeAppUITests.swift` and `ReServeAppUITestsLaunchTests.swift` (these can be removed after migration).

## How To Run UI Tests
1. Close extra simulators. From the Simulator menu, choose `Quit Simulator`.
2. In Xcode, select the `ReServeAppUITests` scheme.
3. Press ⌘U (Product > Test) to run all UI tests. Only one simulator should launch (in portrait orientation).
4. View results in the Test navigator or the report navigator.

## Best Practices (2026)
- Always set the orientation at the start of each test (see code samples below).
- Use the new Swift Testing macros: `@Suite`, `@Test`, `@Setup`.
- Structure tests with clear Maestro-style comments for easy cross-tool maintenance.
- Use helper functions for repeated UI flows.
- Keep old XCTest files only if you need legacy compatibility.

## Example Setup in UI Test Code
```swift
@Setup
mutating func setUp() async throws {
    app = try await Application.launch()
    await app.setOrientation(.portrait) // Always start in portrait
}
