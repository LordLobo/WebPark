//
//  WebPark+postTests.swift
//
//
//  Created by Enhanced Test Suite
//

import Foundation
import XCTest
@testable import WebPark

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class WebPark_post_Tests: XCTestCase {
    
    func BuildPOSTURLSession() -> URLSession {
        let postURL = URL(string: "https://lordlobo.mockapi.com/cats")!
        let errorURL = URL(string: "https://lordlobo.mockapi.com/catserror")!
        
        let response201 = HTTPURLResponse(url: postURL,
                                          statusCode: 201,
                                          httpVersion: nil,
                                          headerFields: ["Content-Type": "application/json"])!
        
        let response400 = HTTPURLResponse(url: errorURL,
                                          statusCode: 400,
                                          httpVersion: nil,
                                          headerFields: nil)!
        
        let responseData = """
        {
            "id": "123",
            "name": "Fluffy",
            "color": "Gray"
        }
        """.data(using: .utf8)
        
        URLProtocolMock.setMock([
            (postURL, (error: nil, data: responseData, response: response201)),
            (errorURL, (error: nil, data: nil, response: response400))
        ])
        
        let session = URLSessionConfiguration.ephemeral
        session.protocolClasses = [URLProtocolMock.self]
        
        return URLSession(configuration: session)
    }
    
    func test_post_withValidData_returnsCreatedObject() async throws {
        let sut = Implementation(urlSession: BuildPOSTURLSession())
        let newCat = Cat(name: "Fluffy", color: "Gray")
        
        let result: Cat = try await sut.post("/cats", body: newCat)
        
        XCTAssertEqual(result.name, "Fluffy", "Should return the posted cat")
        XCTAssertEqual(result.color, "Gray", "Should return correct color")
    }
    
    func test_post_withBadRequest_throwsError() async throws {
        let sut = Implementation(urlSession: BuildPOSTURLSession())
        let newCat = Cat(name: "Invalid", color: "None")
        
        do {
            let _: Cat = try await sut.post("/catserror", body: newCat)
            XCTFail("Should have thrown an error for 400 response")
        } catch let error as WebParkHttpError {
            XCTAssertTrue(error.httpError.rawValue >= 400, "Should throw 4xx error")
        }
    }
}

extension Implementation {
    func post<T: Codable, D: Codable>(_ endpoint: String, body: D) async throws -> T {
        return try await post(endpoint, body: body)
    }
}