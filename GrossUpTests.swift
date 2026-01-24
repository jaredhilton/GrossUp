import XCTest
@testable import GrossUp

final class GrossUpTests: XCTestCase {
    func testGrossCalculation() {
        let gross = GrossUpMath.gross(net: 1000, totalDeductions: 25)
        XCTAssertNotNil(gross)
        XCTAssertEqual(gross!, 1333.3333, accuracy: 0.01)
    }

    func testGrossInvalidTotals() {
        XCTAssertNil(GrossUpMath.gross(net: 1000, totalDeductions: 100))
        XCTAssertNil(GrossUpMath.gross(net: 1000, totalDeductions: -1))
    }

    func testGrossInvalidNet() {
        XCTAssertNil(GrossUpMath.gross(net: 0, totalDeductions: 10))
    }
    
    // MARK: - Net Calculation Tests
    
    func testNetCalculation() {
        let net = GrossUpMath.net(gross: 100, totalDeductions: 25)
        XCTAssertNotNil(net)
        XCTAssertEqual(net!, 75.0, accuracy: 0.01)
    }
    
    func testNetCalculationWithZeroDeductions() {
        let net = GrossUpMath.net(gross: 100, totalDeductions: 0)
        XCTAssertNotNil(net)
        XCTAssertEqual(net!, 100.0, accuracy: 0.01)
    }
    
    func testNetInvalidTotals() {
        XCTAssertNil(GrossUpMath.net(gross: 1000, totalDeductions: 100))
        XCTAssertNil(GrossUpMath.net(gross: 1000, totalDeductions: -1))
    }
    
    func testNetInvalidGross() {
        XCTAssertNil(GrossUpMath.net(gross: 0, totalDeductions: 10))
    }
    
    // MARK: - Round-trip Tests
    
    func testGrossNetRoundTrip() {
        // Start with net, calculate gross, then calculate net back
        let originalNet = 1000.0
        let deductions = 25.0
        
        let gross = GrossUpMath.gross(net: originalNet, totalDeductions: deductions)
        XCTAssertNotNil(gross)
        
        let netBack = GrossUpMath.net(gross: gross!, totalDeductions: deductions)
        XCTAssertNotNil(netBack)
        XCTAssertEqual(netBack!, originalNet, accuracy: 0.01)
    }
}
