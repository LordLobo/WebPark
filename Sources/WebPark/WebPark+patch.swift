//
//  WebPark+patch.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension WebPark {
    
    func patch<T, D>(_ endpoint: String,
                     body: D) async throws -> T where T:Codable, D: Codable {
        
        guard var request = try createRequest("PATCH",
                                              endpoint: endpoint,
                                              isJSON: true) else {
            throw WebParkError.unableToMakeRequest
        }
        
        request.httpBody = try Coder.encode(body)
        
        let (data, response) = try await urlSession.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode >= 400 {
            throw WebParkHttpError(res.statusCode)
        }
        
        return try Coder.decode(data)
    }
    
}
