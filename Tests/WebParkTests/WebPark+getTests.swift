//
//  File.swift
//  
//
//  Created by Daniel Giralte on 5/29/24.
//

import Foundation
import XCTest
@testable import WebPark

final class WebPark_get_Tests: XCTestCase {
    func test__get__given_no_query_items__returns_data() async throws {
        let sut = Implementation(urlSession: BuildURLSession())
        
        let val = try await sut.getCats()
        
        XCTAssert(val[0].name == "Yuki")
    }
}
