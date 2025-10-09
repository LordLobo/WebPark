//
//  CoderTests.swift
//  WebPark
//
//  Created by Daniel Giralte on 10/9/25.
//

import Foundation
import XCTest
@testable import WebPark

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class CoderTests: XCTestCase {
    
    func test_encode_withValidObject_returnsData() throws {
        let cat = Cat(name: "Whiskers", color: "Orange")
        
        let data: Data = try Coder.encode(cat)
        
        XCTAssertFalse(data.isEmpty, "Should return non-empty data")
        
        // Verify we can decode it back
        let decodedCat: Cat = try Coder.decode(data)
        XCTAssertEqual(decodedCat.name, "Whiskers")
        XCTAssertEqual(decodedCat.color, "Orange")
    }
    
    func test_decode_withValidData_returnsObject() throws {
        let jsonData = """
        {"name": "Fluffy", "color": "Black"}
        """.data(using: .utf8)!
        
        let cat: Cat = try Coder.decode(jsonData)
        
        XCTAssertEqual(cat.name, "Fluffy")
        XCTAssertEqual(cat.color, "Black")
    }
    
    func test_decode_withInvalidData_throwsError() {
        let invalidData = "not json".data(using: .utf8)!
        
        XCTAssertThrowsError(try Coder<Cat>.decode(invalidData)) { error in
            XCTAssertTrue(error is JSONCodingError)
            if let jsonError = error as? JSONCodingError {
                XCTAssertEqual(jsonError, .decodingError)
            }
        }
    }
}
