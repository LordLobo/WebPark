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

struct Implementation: WebPark {
    func refreshToken() {
        
    }
    
    var baseURL =  "https://lordlobo.mockapi.com"
    var token =  "token"
    var urlSession: URLSession
}
