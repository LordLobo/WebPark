//
//  File.swift
//  
//
//  Created by Daniel Giralte on 5/29/24.
//

import Foundation
@testable import WebPark

struct MockCat: Codable {
    var name: String
    var color: String
}

struct Implementation: WebPark {
    var urlSession: URLSession
    
    func refreshToken() {
        
    }
    
    let baseURL =  "https://lordlobo.mockapi.com"
    let token =  "token"
}

func BuildURLSession() -> URLSession {
    let getMockURL = URL(string: "https://lordlobo.mockapi.com/cats")!
    let response = HTTPURLResponse(url: getMockURL,
                                   statusCode: 200,
                                   httpVersion: nil,
                                   headerFields: ["Content-Type": "application/json"])!
    let error: Error? = nil
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
    
    URLProtocolMock.mockURLs = [
        getMockURL: (error, data, response)
    ]
            
    let session = URLSessionConfiguration.ephemeral
    session.protocolClasses = [URLProtocolMock.self]
    
    return URLSession(configuration: session)
}

extension Implementation {
    func getCats() async throws -> [MockCat] {
        return try await get("/cats")
    }
}
