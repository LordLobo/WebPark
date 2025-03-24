//
//  WebParkTests.swift
//
//
//  Created by Daniel Giralte on 6/5/22.
//

import XCTest
@testable import WebPark

final class WebParkTests: XCTestCase {
    func test__createRequest__given_valid_request__returns_request() throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 baseURL: "http://google.com/",
                                 urlSession: BuildGETURLSession())
        
        let result = try sut.createRequest("GET", endpoint: "foo")
        
        XCTAssertNotNil(result)
    }
}
