//
//  WebPark+deleteTests.swift
//
//
//  Created by Daniel Giralte on 5/31/24.
//

import Foundation
import XCTest
@testable import WebPark

final class WebPark_delete_Tests: XCTestCase {
    func test__delete__given_no_query_items__does_not_throw() async throws {
        let sut = Implementation(urlSession: BuildDELETEURLSession())
        
        // Should not throw any error
        try await sut.deleteCat()
        
        // If we get here, the test passed - no need for meaningless assertion
    }
    
    func test__delete__given_query_items__does_not_throw() async throws {
        let sut = Implementation(urlSession: BuildDELETEURLSession())
        
        // Should not throw any error
        try await sut.deleteCatQuery()
        
        // If we get here, the test passed
    }
    
    func test__delete__given_unauthorized__throws_with_401() async throws {
        let sut = Implementation(urlSession: BuildDELETEURLSession())
        
        do {
            try await sut.deleteCats401()
            XCTFail("Should have thrown an error for 401 response")
        } catch let error as WebParkHttpError {
            XCTAssertEqual(error.httpError, .unauthorized, "Should throw 401 unauthorized error")
        } catch {
            XCTFail("Should have thrown WebParkHttpError, but got: \(error)")
        }
    }
}

