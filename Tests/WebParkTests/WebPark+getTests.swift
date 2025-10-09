//
//  WebPark+getTests.swift
//  
//
//  Created by Daniel Giralte on 5/29/24.
//

import Foundation
import XCTest
@testable import WebPark

final class WebPark_get_Tests: XCTestCase {
    func test__get__given_no_query_items__returns_data() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        
        let val = try await sut.getCats()
        
        XCTAssert(val[0].name == "Yuki")
    }
    
    func test__get__given_query_items__returns_data() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        
        let val = try await sut.getCatsQuery()
        
        XCTAssert(val[0].name == "Yuki")
    }
    
    func test__get__given_unauthorized__throws_with_401() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        do {
            _ = try await sut.getCats401()
        } catch {
            let err = error as! WebParkHttpError
            XCTAssert(err.httpError == ErrorResponseCode.unauthorized)
        }
    }
    
    func test_get_withValidResponse_returnsDecodedData() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        
        let cats: [Cat] = try await sut.getCats()
        
        XCTAssertEqual(cats.count, 2, "Should return 2 cats")
        XCTAssertEqual(cats[0].name, "Yuki", "First cat should be Yuki")
        XCTAssertEqual(cats[0].color, "Brown", "Yuki should be brown")
        XCTAssertEqual(cats[1].name, "Carl", "Second cat should be Carl")
        XCTAssertEqual(cats[1].color, "White", "Carl should be white")
    }
    
    func test_get_withQueryItems_returnsDecodedData() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        
        let cats: [Cat] = try await sut.getCatsQuery()
        
        XCTAssertEqual(cats.count, 2, "Should return 2 cats even with query")
        XCTAssertEqual(cats[0].name, "Yuki", "First cat should still be Yuki")
    }
    
    func test_get_withUnauthorizedResponse_throwsWebParkHttpError() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        
        do {
            let _: [Cat] = try await sut.getCats401()
            XCTFail("Should have thrown an error for 401 response")
        } catch let error as WebParkHttpError {
            XCTAssertEqual(error.httpError, .unauthorized, "Should throw 401 unauthorized error")
        } catch {
            XCTFail("Should have thrown WebParkHttpError, but got: \(error)")
        }
    }
}
