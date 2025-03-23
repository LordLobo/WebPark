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
    var token = "token"
    
    func refreshToken() async throws {
        
    }
}

struct Implementation: WebPark {
    var tokenService: (any WebParkTokenServiceProtocol)?
    
    var baseURL =  "https://lordlobo.mockapi.com"
    var token =  "token"
    var urlSession: URLSession
}


