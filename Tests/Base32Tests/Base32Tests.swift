@testable import Base32
import XCTest

final class Base32Tests: XCTestCase {
    func testBase32Roundtrip() throws {
        for count in 0..<512 {
            var rng = SystemRandomNumberGenerator()
            let bytes: [UInt8] = (0..<count).map { _ in rng.next() }
            XCTAssertEqual(Array(base32Encoded: bytes.base32EncodedString()), bytes)
        }
    }
}
