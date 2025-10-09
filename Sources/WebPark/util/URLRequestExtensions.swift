//
//  URLRequestExtensions.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

extension URLRequest {    
    public func addingBearerAuthorization(token: String) -> URLRequest {
        var request = self
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    public func acceptingJSON() -> URLRequest {
        var request = self
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    public func sendingJSON() -> URLRequest {
        var request = self
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
