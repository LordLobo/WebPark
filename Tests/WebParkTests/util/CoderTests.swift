//
//  CoderTests.swift
//  WebPark
//
//  Created by Daniel Giralte on 10/9/25.
//

import Foundation
import Testing
@testable import WebPark

@Suite("Coder Tests")
struct CoderTests {
    @Test("Encode with valid object returns data")
    func encodeWithValidObject() async throws {
        let cat = Cat(name: "Whiskers", color: "Orange")
        
        let data: Data = try Coder.encode(cat)
        
        #expect(!data.isEmpty, "Should return non-empty data")
        
        // Verify we can decode it back
        let decodedCat: Cat = try Coder.decode(data)
        #expect(decodedCat.name == "Whiskers")
        #expect(decodedCat.color == "Orange")
    }
    
    @Test("Decode with valid data returns object")
    func decodeWithValidData() async throws {
        let jsonData = """
        {"name": "Fluffy", "color": "Black"}
        """.data(using: .utf8)!
        
        let cat: Cat = try Coder.decode(jsonData)
        
        #expect(cat.name == "Fluffy")
        #expect(cat.color == "Black")
    }
    
    @Test("Decode with invalid data throws error")
    func decodeWithInvalidData() async throws {
        let invalidData = "not json".data(using: .utf8)!
        
        #expect(throws: WebParkError.self) {
            let _: Cat = try Coder.decode(invalidData)
        }
    }
}
