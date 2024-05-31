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
        
        do {
            _ = try await sut.deleteCat()
            XCTAssert(1 == 1)
        } catch {
            XCTFail("This should not throw")
        }
    }
    
    func test__delete__given_query_items__does_not_throw() async throws {
        let sut = Implementation(urlSession: BuildDELETEURLSession())
        
        do {
            _ = try await sut.deleteCatQuery()
            XCTAssert(1 == 1)
        } catch {
            XCTFail("This should not throw")
        }
    }
    
    func test__delete__given_unauthorized__throws_with_401() async throws {
        let sut = Implementation(urlSession: BuildDELETEURLSession())
        
        do {
            _ = try await sut.deleteCats401()
        } catch {
            let err = error as! WebParkHttpError
            XCTAssert(err.httpError == ErrorResponseCode.unauthorized)
        }
    }
}

