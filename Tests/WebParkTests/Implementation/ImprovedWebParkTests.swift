//
//  ImprovedWebParkTests.swift
//
//
//  Enhanced test suite for WebPark
//

import Foundation
import XCTest
@testable import WebPark

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class ImprovedWebParkTests: XCTestCase {
    
    // MARK: - GET Tests
    
    func test_get_withValidResponse_returnsDecodedData() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        
        let cats: [Cat] = try await sut.getCats()
        
        XCTAssertEqual(cats.count, 2, "Should return 2 cats")
        XCTAssertEqual(cats[0].name, "Yuki", "First cat should be Yuki")
        XCTAssertEqual(cats[0].color, "Brown", "Yuki should be brown")
        XCTAssertEqual(cats[1].name, "Carl", "Second cat should be Carl")
        XCTAssertEqual(cats[1].color, "White", "Carl should be white")
    }
    
    func test_get_withQueryItems_returnsDecodedData() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        
        let cats: [Cat] = try await sut.getCatsQuery()
        
        XCTAssertEqual(cats.count, 2, "Should return 2 cats even with query")
        XCTAssertEqual(cats[0].name, "Yuki", "First cat should still be Yuki")
    }
    
    func test_get_withUnauthorizedResponse_throwsWebParkHttpError() async throws {
        let sut = Implementation(tokenService: testTokenService(),
                                 urlSession: BuildGETURLSession())
        
        do {
            let _: [Cat] = try await sut.getCats401()
            XCTFail("Should have thrown an error for 401 response")
        } catch let error as WebParkHttpError {
            XCTAssertEqual(error.httpError, .unauthorized, "Should throw 401 unauthorized error")
        } catch {
            XCTFail("Should have thrown WebParkHttpError, but got: \(error)")
        }
    }
    
    // MARK: - URL Request Creation Tests
    
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
    
    func test_createRequest_withInvalidBaseURL_throwsError() {
        let sut = Implementation(tokenService: nil,
                                 baseURL: "not a valid url",
                                 urlSession: URLSession.shared)
        
        XCTAssertThrowsError(try sut.createRequest("GET", endpoint: "/users")) { error in
            XCTAssertTrue(error is WebParkError, "Should throw WebParkError")
            if let webParkError = error as? WebParkError {
                XCTAssertEqual(webParkError, .unableToMakeURL, "Should throw unableToMakeURL error")
            }
        }
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
}

// MARK: - Coder Tests

final class CoderTests: XCTestCase {
    
    func test_encode_withValidObject_returnsData() throws {
        let cat = Cat(name: "Whiskers", color: "Orange")
        
        let data: Data = try Coder.encode(cat)
        
        XCTAssertFalse(data.isEmpty, "Should return non-empty data")
        
        // Verify we can decode it back
        let decodedCat: Cat = try Coder.decode(data)
        XCTAssertEqual(decodedCat.name, "Whiskers")
        XCTAssertEqual(decodedCat.color, "Orange")
    }
    
    func test_decode_withValidData_returnsObject() throws {
        let jsonData = """
        {"name": "Fluffy", "color": "Black"}
        """.data(using: .utf8)!
        
        let cat: Cat = try Coder.decode(jsonData)
        
        XCTAssertEqual(cat.name, "Fluffy")
        XCTAssertEqual(cat.color, "Black")
    }
    
    func test_decode_withInvalidData_throwsError() {
        let invalidData = "not json".data(using: .utf8)!
        
        XCTAssertThrowsError(try Coder<Cat>.decode(invalidData)) { error in
            XCTAssertTrue(error is JSONCodingError)
            if let jsonError = error as? JSONCodingError {
                XCTAssertEqual(jsonError, .decodingError)
            }
        }
    }
}

// MARK: - URLRequest Extensions Tests

final class URLRequestExtensionsTests: XCTestCase {
    
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
