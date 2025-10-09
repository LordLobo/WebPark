//
//  WebParkTests.swift
//
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation
import Testing
@testable import WebPark

@Suite("WebPark Core Functionality Tests")
struct WebParkTests {
    @Test("Create request with valid parameters")
    func createRequestWithValidRequest() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 baseURL: "http://google.com/",
                                 urlSession: BuildGETURLSession())
        
        let result = try sut.createRequest("GET", endpoint: "foo")
        
        #expect(result != nil, "Should create a valid request")
    }
    
    @Test("Create request with invalid base URL throws error")
    func createRequestWithInvalidBaseURL() async throws {
        let sut = Implementation(tokenService: nil,
                                 baseURL: "not a valid url with spaces and 🚀",
                                 urlSession: URLSession.shared)
        
        #expect(throws: WebParkError.unableToMakeURL) {
            try sut.createRequest("GET", endpoint: "/users")
        }
    }
    
    @Test("Create request with valid parameters builds correct request")
    func createRequestWithValidParameters() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 baseURL: "https://api.example.com",
                                 urlSession: URLSession.shared)
        
        let request = try sut.createRequest("GET", endpoint: "/users")
        let unwrappedRequest = try #require(request, "Should create a valid request")
        
        #expect(unwrappedRequest.httpMethod == "GET", "Should set correct HTTP method")
        #expect(unwrappedRequest.url?.absoluteString == "https://api.example.com/users", "Should build correct URL")
        #expect(unwrappedRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token", "Should add authorization header")
    }
    
    @Test("Create request with query items builds correct URL")
    func createRequestWithQueryItems() async throws {
        let sut = Implementation(tokenService: nil,
                                 baseURL: "https://api.example.com",
                                 urlSession: URLSession.shared)
        
        let queryItems = [URLQueryItem(name: "limit", value: "10")]
        let request = try sut.createRequest("GET", endpoint: "/users", queryItems: queryItems)
        let unwrappedRequest = try #require(request, "Should create a valid request")
        
        #expect(unwrappedRequest.url?.absoluteString.contains("limit=10") == true, "Should include query parameters")
    }
    
    @Test("Create request with JSON flag sets content type header")
    func createRequestWithJSONFlag() async throws {
        let sut = Implementation(tokenService: nil,
                                 baseURL: "https://api.example.com",
                                 urlSession: URLSession.shared)
        
        let request = try sut.createRequest("POST", endpoint: "/users", isJSON: true)
        
        #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json", "Should set JSON content type")
    }
        
    // MARK: - Error Response Code Tests
    
    @Suite("Error Response Code Tests")
    struct ErrorResponseCodeTests {
        @Test("Initialize with known codes returns correct enum")
        func initWithKnownCodes() async throws {
            #expect(ErrorResponseCode(rawValue: 401) == .unauthorized)
            #expect(ErrorResponseCode(rawValue: 404) == .notFound)
            #expect(ErrorResponseCode(rawValue: 500) == .internalServerError)
            #expect(ErrorResponseCode(rawValue: 503) == .serviceUnavailable)
        }
        
        @Test("Initialize with unknown code returns nil")
        func initWithUnknownCode() async throws {
            #expect(ErrorResponseCode(rawValue: 418) == nil)
        }
        
        @Test("WebParkHttpError initializes with status code creates correct error")
        func webParkHttpErrorInit() async throws {
            let error401 = WebParkHttpError(401)
            #expect(error401.httpError == .unauthorized)
            #expect(error401.statusCode == 401)
            #expect(error401.description == "HTTP 401: Unauthorized")
            
            let error999 = WebParkHttpError(999)
            #expect(error999.httpError == .unhandledResponseCode)
            #expect(error999.statusCode == 999)
        }
    }
    
    // MARK: - URLRequest Extension Tests
    
    @Suite("URLRequest Extension Tests")
    struct URLRequestExtensionTests {
        @Test("Adding bearer authorization sets auth header")
        func addingBearerAuthorization() async throws {
            let url = URL(string: "https://api.example.com")!
            let request = URLRequest(url: url)
            
            let authorizedRequest = request.addingBearerAuthorization(token: "test-token")
            
            #expect(authorizedRequest.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        }
        
        @Test("Sending JSON sets content type header")
        func sendingJSON() async throws {
            let url = URL(string: "https://api.example.com")!
            let request = URLRequest(url: url)
            
            let jsonRequest = request.sendingJSON()
            
            #expect(jsonRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        }
        
        @Test("Accepting JSON sets accept header")
        func acceptingJSON() async throws {
            let url = URL(string: "https://api.example.com")!
            let request = URLRequest(url: url)
            
            let jsonRequest = request.acceptingJSON()
            
            #expect(jsonRequest.value(forHTTPHeaderField: "Accept") == "application/json")
        }
    }
}
