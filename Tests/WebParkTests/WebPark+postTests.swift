//
//  WebPark+postTests.swift
//
//
//  Created by Enhanced Test Suite
//

import Foundation
import Testing
@testable import WebPark

func BuildPOSTURLSession() -> URLSession {
    // Don't call removeAllMocks() - let different test suites coexist
    // Use unique URLs for POST tests to avoid conflicts with other suites
    
    let postURL = URL(string: "https://lordlobo.mockapi.com/postcats")!
    let errorURL = URL(string: "https://lordlobo.mockapi.com/postcatserror")!
    
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
        "name": "Fluffy",
        "color": "Gray"
    }
    """.data(using: .utf8)
    
    let noError: Error? = nil
    
    URLProtocolMock.setMock([
        (postURL, (error: noError, data: responseData, response: response201)),
        (errorURL, (error: noError, data: nil, response: response400))
    ])
    
    let session = URLSessionConfiguration.ephemeral
    session.protocolClasses = [URLProtocolMock.self]
    
    return URLSession(configuration: session)
}

@Suite("WebPark POST Tests", .serialized)
struct WebPark_post_Tests {
    let sut = Implementation(urlSession: BuildPOSTURLSession())
    
    @Test("POST with valid data returns created object")
    func postWithValidDataReturnsCreatedObject() async throws {
        let newCat = Cat(name: "Fluffy", color: "Gray")
        
        let result: Cat = try await sut.post("/postcats", body: newCat)
        
        #expect(result.name == "Fluffy", "Should return the posted cat")
        #expect(result.color == "Gray", "Should return correct color")
    }
    
    @Test("POST with bad request throws error")
    func postWithBadRequestThrowsError() async throws {
        let newCat = Cat(name: "Invalid", color: "None")
        
        do {
            let _: Cat = try await sut.post("/postcatserror", body: newCat)
            Issue.record("Should have thrown an error for 400 response")
        } catch let error as WebParkHttpError {
            #expect(error.httpError.rawValue >= 400, "Should throw 4xx error")
        }
    }
}

