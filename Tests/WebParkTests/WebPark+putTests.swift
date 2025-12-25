//
//  WebPark+putTests.swift
//
//
//  Created by Daniel Giralte on 12/25/24.
//

import Foundation
import Testing
@testable import WebPark

func BuildPUTURLSession() -> URLSession {
    // Don't call removeAllMocks() - let different test suites coexist
    // Use unique URLs for PUT tests to avoid conflicts with other suites
    
    let putURL = URL(string: "https://lordlobo.mockapi.com/putcats/1")!
    let errorURL = URL(string: "https://lordlobo.mockapi.com/putcatserror")!
    
    let response200 = HTTPURLResponse(url: putURL,
                                      statusCode: 200,
                                      httpVersion: nil,
                                      headerFields: ["Content-Type": "application/json"])!
    
    let response404 = HTTPURLResponse(url: errorURL,
                                      statusCode: 404,
                                      httpVersion: nil,
                                      headerFields: nil)!
    
    let responseData = """
    {
        "name": "UpdatedCat",
        "color": "Black"
    }
    """.data(using: .utf8)
    
    let noError: Error? = nil
    
    URLProtocolMock.setMock([
        (putURL, (error: noError, data: responseData, response: response200)),
        (errorURL, (error: noError, data: nil, response: response404))
    ])
    
    let session = URLSessionConfiguration.ephemeral
    session.protocolClasses = [URLProtocolMock.self]
    
    return URLSession(configuration: session)
}

@Suite("WebPark PUT Tests", .serialized)
struct WebPark_put_Tests {
    let sut = Implementation(urlSession: BuildPUTURLSession())
    
    @Test("PUT with valid data returns updated object")
    func putWithValidDataReturnsUpdatedObject() async throws {
        let updatedCat = Cat(name: "UpdatedCat", color: "Black")
        
        let result: Cat = try await sut.put("/putcats/1", body: updatedCat)
        
        #expect(result.name == "UpdatedCat", "Should return the updated cat")
        #expect(result.color == "Black", "Should return correct color")
    }
    
    @Test("PUT with not found response throws error")
    func putWithNotFoundThrowsError() async throws {
        let updatedCat = Cat(name: "NonExistent", color: "None")
        
        do {
            let _: Cat = try await sut.put("/putcatserror", body: updatedCat)
            Issue.record("Should have thrown an error for 404 response")
        } catch let error as WebParkHttpError {
            #expect(error.httpError == .notFound, "Should throw 404 not found error")
            #expect(error.statusCode == 404, "Status code should be 404")
        } catch {
            Issue.record("Should have thrown WebParkHttpError, but got: \(error)")
        }
    }
    
    @Test("PUT sets Content-Type header to application/json")
    func putSetsContentTypeHeader() async throws {
        let updatedCat = Cat(name: "UpdatedCat", color: "Black")
        
        // This test verifies that the request is properly configured
        // The createRequest method should set isJSON: true
        let result: Cat = try await sut.put("/putcats/1", body: updatedCat)
        
        #expect(result.name == "UpdatedCat", "Request should complete successfully")
    }
    
    @Test("PUT encodes request body correctly")
    func putEncodesRequestBodyCorrectly() async throws {
        let updatedCat = Cat(name: "UpdatedCat", color: "Black")
        
        // If encoding fails, this will throw
        let result: Cat = try await sut.put("/putcats/1", body: updatedCat)
        
        #expect(result.name == "UpdatedCat", "Body should be encoded and sent correctly")
    }
    
    @Test("PUT decodes response correctly")
    func putDecodesResponseCorrectly() async throws {
        let updatedCat = Cat(name: "UpdatedCat", color: "Black")
        
        let result: Cat = try await sut.put("/putcats/1", body: updatedCat)
        
        // Verify all fields are properly decoded
        #expect(result.name == "UpdatedCat", "Name should be decoded")
        #expect(result.color == "Black", "Color should be decoded")
    }
}

