//
//  delete.swift
//
//
//  Created by Daniel Giralte on 5/31/24.
//
import Foundation
@testable import WebPark

func BuildDELETEURLSession() -> URLSession {
    let getMockBaseDELETEURL = URL(string: "https://lordlobo.mockapi.com/deletecats")!
    let getMockQueryDELETEURL = URL(string: "https://lordlobo.mockapi.com/deletecats?count=2")!
    let getMockErrorDELETEURL = URL(string: "https://lordlobo.mockapi.com/deletecatserror")!
    
    let response200 = HTTPURLResponse(url: getMockBaseDELETEURL,
                                      statusCode: 200,
                                      httpVersion: nil,
                                      headerFields: ["Content-Type": "application/json"])!
    
    let response401 = HTTPURLResponse(url: getMockBaseDELETEURL,
                                      statusCode: 401,
                                      httpVersion: nil,
                                      headerFields: nil)!
    
    let noError: Error? = nil
    
    URLProtocolMock.setMock([
        (getMockBaseDELETEURL, (error: noError, data: nil, response: response200)),
        (getMockQueryDELETEURL, (error: noError, data: nil, response: response200)),
        (getMockErrorDELETEURL, (error: noError, data: nil, response: response401))
    ])
    
    let session = URLSessionConfiguration.ephemeral
    session.protocolClasses = [URLProtocolMock.self]
    
    return URLSession(configuration: session)
}

extension Implementation {
    func deleteCat() async throws -> Void {
        return try await delete("/deletecats")
    }
    
    func deleteCatQuery() async throws -> Void {
        let query = [URLQueryItem(name: "count", value: "2")]
        return try await delete("/deletecats", queryItems: query)
    }
    
    func deleteCats401() async throws -> Void {
        return try await delete("/deletecatserror")
    }
}

