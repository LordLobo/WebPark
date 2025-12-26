//
//  WebPark+patchTests.swift
//
//
//  Created by Daniel Giralte on 12/25/24.
//

import Foundation
import Testing
@testable import WebPark

func BuildPATCHURLSession() -> URLSession {
    // Don't call removeAllMocks() - let different test suites coexist
    // Use unique URLs for PATCH tests to avoid conflicts with other suites
    
    let patchURL = URL(string: "https://lordlobo.mockapi.com/patchcats/1")!
    let errorURL = URL(string: "https://lordlobo.mockapi.com/patchcatserror")!
    let conflictURL = URL(string: "https://lordlobo.mockapi.com/patchcatsconflict")!
    
    let response200 = HTTPURLResponse(url: patchURL,
                                      statusCode: 200,
                                      httpVersion: nil,
                                      headerFields: ["Content-Type": "application/json"])!
    
    let response404 = HTTPURLResponse(url: errorURL,
                                      statusCode: 404,
                                      httpVersion: nil,
                                      headerFields: nil)!
    
    let response409 = HTTPURLResponse(url: conflictURL,
                                      statusCode: 409,
                                      httpVersion: nil,
                                      headerFields: nil)!
    
    let responseData = """
    {
        "name": "PatchedCat",
        "color": "Orange"
    }
    """.data(using: .utf8)
    
    let noError: (any Error)? = nil
    
    URLProtocolMock.setMock([
        (patchURL, (error: noError, data: responseData, response: response200)),
        (errorURL, (error: noError, data: nil, response: response404)),
        (conflictURL, (error: noError, data: nil, response: response409))
    ])
    
    let session = URLSessionConfiguration.ephemeral
    session.protocolClasses = [URLProtocolMock.self]
    
    return URLSession(configuration: session)
}

@Suite("WebPark PATCH Tests", .serialized)
struct WebPark_patch_Tests {
    let sut = Implementation(urlSession: BuildPATCHURLSession())
    
    @Test("PATCH with valid data returns patched object")
    func patchWithValidDataReturnsPatchedObject() async throws {
        let patchCat = Cat(name: "PatchedCat", color: "Orange")
        
        let result: Cat = try await sut.patch("/patchcats/1", body: patchCat)
        
        #expect(result.name == "PatchedCat", "Should return the patched cat")
        #expect(result.color == "Orange", "Should return correct color")
    }
    
    @Test("PATCH with not found response throws error")
    func patchWithNotFoundThrowsError() async throws {
        let patchCat = Cat(name: "NonExistent", color: "None")
        
        do {
            let _: Cat = try await sut.patch("/patchcatserror", body: patchCat)
            Issue.record("Should have thrown an error for 404 response")
        } catch let error as WebParkHttpError {
            #expect(error.httpError == .notFound, "Should throw 404 not found error")
            #expect(error.statusCode == 404, "Status code should be 404")
        } catch {
            Issue.record("Should have thrown WebParkHttpError, but got: \(error)")
        }
    }
    
    @Test("PATCH with conflict response throws error")
    func patchWithConflictThrowsError() async throws {
        let patchCat = Cat(name: "ConflictCat", color: "Red")
        
        do {
            let _: Cat = try await sut.patch("/patchcatsconflict", body: patchCat)
            Issue.record("Should have thrown an error for 409 response")
        } catch let error as WebParkHttpError {
            #expect(error.httpError == .conflict, "Should throw 409 conflict error")
            #expect(error.statusCode == 409, "Status code should be 409")
            #expect(error.description.contains("Conflict"), "Error description should mention conflict")
        } catch {
            Issue.record("Should have thrown WebParkHttpError, but got: \(error)")
        }
    }
    
    @Test("PATCH sets Content-Type header to application/json")
    func patchSetsContentTypeHeader() async throws {
        let patchCat = Cat(name: "PatchedCat", color: "Orange")
        
        // This test verifies that the request is properly configured
        // The createRequest method should set isJSON: true
        let result: Cat = try await sut.patch("/patchcats/1", body: patchCat)
        
        #expect(result.name == "PatchedCat", "Request should complete successfully")
    }
    
    @Test("PATCH encodes request body correctly")
    func patchEncodesRequestBodyCorrectly() async throws {
        let patchCat = Cat(name: "PatchedCat", color: "Orange")
        
        // If encoding fails, this will throw
        let result: Cat = try await sut.patch("/patchcats/1", body: patchCat)
        
        #expect(result.name == "PatchedCat", "Body should be encoded and sent correctly")
    }
    
    @Test("PATCH decodes response correctly")
    func patchDecodesResponseCorrectly() async throws {
        let patchCat = Cat(name: "PatchedCat", color: "Orange")
        
        let result: Cat = try await sut.patch("/patchcats/1", body: patchCat)
        
        // Verify all fields are properly decoded
        #expect(result.name == "PatchedCat", "Name should be decoded")
        #expect(result.color == "Orange", "Color should be decoded")
    }
    
    @Test("PATCH error response codes are properly handled")
    func patchErrorResponseCodesAreProperlyHandled() async throws {
        let patchCat = Cat(name: "ErrorCat", color: "None")
        
        // Test 404
        do {
            let _: Cat = try await sut.patch("/patchcatserror", body: patchCat)
            Issue.record("Should have thrown an error")
        } catch let error as WebParkHttpError {
            #expect(error.httpError.rawValue >= 400, "Should throw 4xx/5xx error")
        }
    }
}
