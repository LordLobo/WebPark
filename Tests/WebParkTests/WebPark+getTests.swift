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
        let sut = Implementation(urlSession: BuildGETURLSession())
        
        let val = try await sut.getCats()
        
        XCTAssert(val[0].name == "Yuki")
    }
    
    func test__get__given_query_items__returns_data() async throws {
        let sut = Implementation(urlSession: BuildGETURLSession())
        
        let val = try await sut.getCatsQuery()
        
        XCTAssert(val[0].name == "Yuki")
    }
    
    func test__get__given_unauthorized__throws_with_401() async throws {
        let sut = Implementation(urlSession: BuildGETURLSession())
        do {
            _ = try await sut.getCats401()
        } catch {
            let err = error as! WebParkHttpError
            XCTAssert(err.httpError == ErrorResponseCode.unauthorized)
        }
    }
}
