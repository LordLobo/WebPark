//
//  WebPark.swift
//
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation


/**
 A lightweight protocol that defines the essentials for making web requests
 in a WebPark-powered client.

 Conform to `WebPark` to centralize your networking configuration such as
 the base API URL, the `URLSession` to use for requests, and an optional
 token service for authenticated calls.
 */
public protocol WebPark {
    /// The base URL for your API, e.g. "https://api.example.com".
    ///
    /// This value is concatenated with relative endpoint paths when building requests.
    var baseURL: String { get }
    
    /// The `URLSession` used to execute network requests.
    ///
    /// A default implementation provides `URLSession.shared` via a protocol extension.
    /// Override by supplying your own session when needed (e.g. for custom configuration
    /// or testing with mocked sessions).
    var urlSession: URLSession { get }
    
    /// Optional token service used to attach and refresh a bearer token for authenticated requests.
    ///
    /// When present, `createRequest(_:endpoint:queryItems:isJSON:)` automatically adds an
    /// `Authorization: Bearer <token>` header using `tokenService.token`.
    /// Implementations may call `tokenService.refreshToken()` upon receiving an HTTP 401
    /// to refresh credentials and retry as appropriate.
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

public enum ErrorResponseCode: Int, Sendable {
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

