//
//  WebPark.swift
//
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

/// 
public protocol WebPark {
    var baseURL: String { get }
    
    var urlSession: URLSession { get }
    
    // possible fix for token refresh - token service that catches 401s
    var tokenService: WebParkTokenServiceProtocol? { get }
}

public protocol WebParkTokenServiceProtocol {
    var token: String { get }
    
    func refreshToken() async throws
}

extension WebPark {
    var urlSession: URLSession { URLSession.shared }
    
    internal func createRequest(_ method: String,
                                endpoint: String,
                                queryItems: [URLQueryItem] = [],
                                isJSON: Bool = false) throws -> URLRequest? {
        
        guard var urlComponents = URLComponents(string: self.baseURL + endpoint)
        else {
            throw WebParkError.unableToMakeURL
        }
        
        if queryItems.hasItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else { throw WebParkError.unableToMakeURL}
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let tokenService {
            request = request.addingBearerAuthorization(token: tokenService.token)
        }
        
        if isJSON {
            request = request.sendingJSON()
        }
        
        return request
    }    
}

public enum WebParkError: Error {
    case unableToMakeURL
    case unableToMakeRequest
    case decodeFailure
    case unableToMakeAuthdRequest
    case encodeFailure
}

public enum ErrorResponseCode: Int {
    case unauthorized = 401
    case notFound = 404
    case internalServerError = 500
    case notImplemented = 501
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    
    case unhandledResponseCode = 0
}

public struct WebParkHttpError: Error {
    public var httpError: ErrorResponseCode
    
    public init(_ withError: Int) {
        httpError = ErrorResponseCode(rawValue: withError) ?? .unhandledResponseCode
    }
}

