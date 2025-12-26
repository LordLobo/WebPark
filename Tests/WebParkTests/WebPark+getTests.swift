//
//  WebPark+getTests.swift
//
//
//  Created by Daniel Giralte on 5/29/24.
//

import Foundation
import Testing
@testable import WebPark

@Suite("WebPark GET Tests", .serialized)
struct WebPark_get_Tests {
    let sut = Implementation(tokenService: testTokenService(),
                             urlSession: BuildGETURLSession())
    
    @Test("GET with no query items returns data")
    func getWithNoQueryItemsReturnsData() async throws {
        let val = try await sut.getCats()
        
        #expect(val[0].name == "Yuki")
    }
    
    @Test("GET with query items returns data")
    func getWithQueryItemsReturnsData() async throws {
        let val = try await sut.getCatsQuery()
        
        #expect(val[0].name == "Yuki")
    }
    
    @Test("GET with unauthorized response throws with 401")
    func getWithUnauthorizedThrowsWith401() async throws {
        await #expect(throws: WebParkHttpError.self) {
            try await sut.getCats401()
        }
        
        // If you need to verify the specific error code:
        do {
            _ = try await sut.getCats401()
            Issue.record("Expected error to be thrown")
        } catch let error as WebParkHttpError {
            #expect(error.httpError == ErrorResponseCode.unauthorized)
        }
    }
    
    @Test("GET with valid response returns decoded data")
    func getWithValidResponseReturnsDecodedData() async throws {
        let cats: [Cat] = try await sut.getCats()
        
        #expect(cats.count == 2, "Should return 2 cats")
        #expect(cats[0].name == "Yuki", "First cat should be Yuki")
        #expect(cats[0].color == "Brown", "Yuki should be brown")
        #expect(cats[1].name == "Carl", "Second cat should be Carl")
        #expect(cats[1].color == "White", "Carl should be white")
    }
    
    @Test("GET with query items returns decoded data")
    func getWithQueryItemsReturnsDecodedData() async throws {
        let cats: [Cat] = try await sut.getCatsQuery()
        
        #expect(cats.count == 2, "Should return 2 cats even with query")
        #expect(cats[0].name == "Yuki", "First cat should still be Yuki")
    }
    
    @Test("GET with unauthorized response throws WebParkHttpError")
    func getWithUnauthorizedResponseThrowsWebParkHttpError() async throws {
        do {
            let _: [Cat] = try await sut.getCats401()
            Issue.record("Should have thrown an error for 401 response")
        } catch let error as WebParkHttpError {
            #expect(error.httpError == .unauthorized, "Should throw 401 unauthorized error")
        } catch {
            Issue.record("Should have thrown WebParkHttpError, but got: \(error)")
        }
    }
}
