//
//  WebLeopard+patch.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, *)
public extension WebLeopard {
    
    func patch<T, D>(endpoint: String,
                     body: D) async throws -> T where T:Codable, D: Codable {
        
        guard var request = try createLeopardRequest("PATCH", endpoint: endpoint, isJSON: true) else {
            throw WebLeopardError.unableToMakeRequest
        }
        
        request.httpBody = try Coder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
            
        return try Coder<T>.decode(data)
    }
    
}
