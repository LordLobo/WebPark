//
//  WebPark+deleteTests.swift
//
//
//  Created by Daniel Giralte on 5/31/24.
//

import Foundation
import Testing
@testable import WebPark

@Suite("WebPark DELETE Tests", .serialized)
struct WebPark_delete_Tests {
    let sut = Implementation(urlSession: BuildDELETEURLSession())
    
    @Test("DELETE with no query items does not throw")
    func deleteWithNoQueryItemsDoesNotThrow() async throws {
        // Should not throw any error
        try await sut.deleteCat()
        
        // If we get here, the test passed - no need for meaningless assertion
    }
    
    @Test("DELETE with query items does not throw")
    func deleteWithQueryItemsDoesNotThrow() async throws {
        // Should not throw any error
        try await sut.deleteCatQuery()
        
        // If we get here, the test passed
    }
    
    @Test("DELETE with unauthorized response throws with 401")
    func deleteWithUnauthorizedThrowsWith401() async throws {
        do {
            try await sut.deleteCats401()
            Issue.record("Should have thrown an error for 401 response")
        } catch let error as WebParkHttpError {
            #expect(error.httpError == .unauthorized, "Should throw 401 unauthorized error")
        } catch {
            Issue.record("Should have thrown WebParkHttpError, but got: \(error)")
        }
    }
    
    @Test("DELETE returns Void on success")
    func deleteReturnsVoidOnSuccess() async throws {
        let _ : Void = try await sut.deleteCat()
        
        // If we reach this point without throwing, the test passes
        // Void is the expected return type
        #expect(Bool(true), "DELETE should complete successfully and return Void")
    }
    
    @Test("DELETE with query parameters formats URL correctly")
    func deleteWithQueryParametersFormatsURLCorrectly() async throws {
        // The mock is set up to accept the query URL
        // If the URL formatting is incorrect, this will fail
        try await sut.deleteCatQuery()
        
        // Success means the URL with query items was correctly formatted
        #expect(Bool(true), "DELETE with query items should format URL correctly")
    }
    
    @Test("DELETE error contains correct status code")
    func deleteErrorContainsCorrectStatusCode() async throws {
        do {
            try await sut.deleteCats401()
            Issue.record("Should have thrown an error for 401 response")
        } catch let error as WebParkHttpError {
            #expect(error.statusCode == 401, "Error should contain status code 401")
            #expect(error.httpError.rawValue == 401, "Error enum should match status code")
        } catch {
            Issue.record("Should have thrown WebParkHttpError")
        }
    }
    
    @Test("DELETE HttpError has correct description")
    func deleteHttpErrorHasCorrectDescription() async throws {
        do {
            try await sut.deleteCats401()
            Issue.record("Should have thrown an error for 401 response")
        } catch let error as WebParkHttpError {
            let description = error.description
            #expect(description.contains("401"), "Error description should contain status code")
            #expect(description.contains("Unauthorized"), "Error description should contain error name")
        } catch {
            Issue.record("Should have thrown WebParkHttpError")
        }
    }
}


