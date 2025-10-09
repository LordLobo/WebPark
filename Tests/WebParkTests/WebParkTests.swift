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
    
    func test_createRequest_withInvalidBaseURL_throwsError() {
        let sut = Implementation(tokenService: nil,
                                 baseURL: "not a valid url with spaces and 🚀",
                                 urlSession: URLSession.shared)
        
        do {
            _ = try sut.createRequest("GET", endpoint: "/users")
            XCTFail("Should have thrown an error for invalid base URL")
        } catch let error as WebParkError {
            XCTAssertEqual(error, .unableToMakeURL, "Should throw unableToMakeURL error")
        } catch {
            XCTFail("Should have thrown WebParkError, but got: \(error)")
        }
    }
    
    func test_createRequest_withValidParameters_createsCorrectRequest() throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 baseURL: "https://api.example.com",
                                 urlSession: URLSession.shared)
        
        let request = try sut.createRequest("GET", endpoint: "/users")
        
        XCTAssertNotNil(request, "Should create a valid request")
        XCTAssertEqual(request?.httpMethod, "GET", "Should set correct HTTP method")
        XCTAssertEqual(request?.url?.absoluteString, "https://api.example.com/users", "Should build correct URL")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer token", "Should add authorization header")
    }
    
    func test_createRequest_withQueryItems_buildsCorrectURL() throws {
        let sut = Implementation(tokenService: nil,
                                 baseURL: "https://api.example.com",
                                 urlSession: URLSession.shared)
        
        let queryItems = [URLQueryItem(name: "limit", value: "10")]
        let request = try sut.createRequest("GET", endpoint: "/users", queryItems: queryItems)
        
        XCTAssertNotNil(request, "Should create a valid request")
        XCTAssertTrue(request?.url?.absoluteString.contains("limit=10") == true, "Should include query parameters")
    }
    
    func test_createRequest_withJSONFlag_setsContentTypeHeader() throws {
        let sut = Implementation(tokenService: nil,
                                 baseURL: "https://api.example.com",
                                 urlSession: URLSession.shared)
        
        let request = try sut.createRequest("POST", endpoint: "/users", isJSON: true)
        
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json", "Should set JSON content type")
    }
    
    // MARK: - Error Response Code Tests
    
    func test_errorResponseCode_initWithKnownCodes_returnsCorrectEnum() {
        XCTAssertEqual(ErrorResponseCode(rawValue: 401), .unauthorized)
        XCTAssertEqual(ErrorResponseCode(rawValue: 404), .notFound)
        XCTAssertEqual(ErrorResponseCode(rawValue: 500), .internalServerError)
        XCTAssertEqual(ErrorResponseCode(rawValue: 503), .serviceUnavailable)
    }
    
    func test_errorResponseCode_initWithUnknownCode_returnsNil() {
        XCTAssertEqual(ErrorResponseCode(rawValue: 418), nil)
    }
    
    func test_webParkHttpError_initWithStatusCode_createsCorrectError() {
        let error401 = WebParkHttpError(401)
        XCTAssertEqual(error401.httpError, .unauthorized)
        
        let error999 = WebParkHttpError(999)
        XCTAssertEqual(error999.httpError, .unhandledResponseCode)
    }
    
    func test_addingBearerAuthorization_setsAuthHeader() {
        let url = URL(string: "https://api.example.com")!
        let request = URLRequest(url: url)
        
        let authorizedRequest = request.addingBearerAuthorization(token: "test-token")
        
        XCTAssertEqual(authorizedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }
    
    func test_sendingJSON_setsContentTypeHeader() {
        let url = URL(string: "https://api.example.com")!
        let request = URLRequest(url: url)
        
        let jsonRequest = request.sendingJSON()
        
        XCTAssertEqual(jsonRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
    
    func test_acceptingJSON_setsAcceptHeader() {
        let url = URL(string: "https://api.example.com")!
        let request = URLRequest(url: url)
        
        let jsonRequest = request.acceptingJSON()
        
        XCTAssertEqual(jsonRequest.value(forHTTPHeaderField: "Accept"), "application/json")
    }
}
