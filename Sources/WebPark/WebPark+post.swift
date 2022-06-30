//
//  WebPark+post.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, *)
public extension WebPark {
    
    func post<T, D>(_ endpoint: String,
                    body: D) async throws -> T where T:Codable, D:Codable {
        
        guard var request = try createRequest("POST",
                                                     endpoint: endpoint,
                                                     isJSON: true) else {
            throw WebParkError.unableToMakeRequest
        }
        
        request.httpBody = try Coder.encode(body)
                
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
            
        return try Coder.decode(data)
    }
    
}
