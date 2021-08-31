import XCTest
@testable import Base32

final class Base32Tests: XCTestCase {
    func testBase32() throws {
        for count in 0..<512 {
            var rng = SystemRandomNumberGenerator()
            let bytes: [UInt8] = (0..<count).map { _ in rng.next() }
            
            let encoded = bytes.base32Encoded()
            let decoded = try encoded.base32Decoded()
            
            XCTAssertEqual(decoded, bytes)
        }
    }
}
