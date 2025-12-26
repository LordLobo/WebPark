//
//  Implementation.swift
//
//
//  Created by Daniel Giralte on 5/29/24.
//

import Foundation
@testable import WebPark

struct Cat: Codable {
    var name: String
    var color: String
}

struct testTokenService: WebParkTokenServiceProtocol {
    var token: String { "token" }
    
    func refreshToken() async throws {
        // Mock implementation
    }
}

struct Implementation: WebPark {
    var tokenService: (any WebParkTokenServiceProtocol)?
    var baseURL: String
    var urlSession: URLSession
    
    init(tokenService: (any WebParkTokenServiceProtocol)? = nil,
         baseURL: String = "https://lordlobo.mockapi.com",
         urlSession: URLSession) {
        self.tokenService = tokenService
        self.baseURL = baseURL
        self.urlSession = urlSession
    }
}
