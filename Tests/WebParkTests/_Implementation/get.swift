//
//  get.swift
//
//
//  Created by Daniel Giralte on 5/30/24.
//

import Foundation
@testable import WebPark

func BuildGETURLSession() -> URLSession {
    // Don't call removeAllMocks() - let different test suites coexist
    // Each suite uses unique URLs so there's no conflict
    
    let getMockBaseGETURL = URL(string: "https://lordlobo.mockapi.com/cats")!
    let getMockQueryGETURL = URL(string: "https://lordlobo.mockapi.com/cats?count=2")!
    let getMockErrorGETURL = URL(string: "https://lordlobo.mockapi.com/catserror")!
    
    let response200 = HTTPURLResponse(url: getMockBaseGETURL,
                                      statusCode: 200,
                                      httpVersion: nil,
                                      headerFields: ["Content-Type": "application/json"])!
    
    let response401 = HTTPURLResponse(url: getMockBaseGETURL,
                                      statusCode: 401,
                                      httpVersion: nil,
                                      headerFields: nil)!
    
    let noError: (any Error)? = nil
    
    let data =
        """
        [
            {
                "name": "Yuki",
                "color": "Brown"
            },
            {
                "name": "Carl",
                "color": "White"
            }
        ]
        """.data(using: .utf8)
    
    URLProtocolMock.setMock([
        (getMockBaseGETURL, (error: noError, data: data, response: response200)),
        (getMockQueryGETURL, (error: noError, data: data, response: response200)),
        (getMockErrorGETURL, (error: noError, data: nil, response: response401))
    ])
    
    let session = URLSessionConfiguration.ephemeral
    session.protocolClasses = [URLProtocolMock.self]
    
    return URLSession(configuration: session)
}

extension Implementation {
    func getCats() async throws -> [Cat] {
        try await get("/cats")
    }
    
    func getCatsQuery() async throws -> [Cat] {
        let query = [URLQueryItem(name: "count", value: "2")]
        return try await get("/cats", queryItems: query)
    }
    
    func getCats401() async throws -> [Cat] {
        try await get("/catserror")
    }
}
