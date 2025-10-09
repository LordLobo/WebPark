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

public protocol WebParkAsyncTokenServiceProtocol: Sendable {
    /// The current bearer token to be used in Authorization headers
    var token: String { get async }
    
    /// Refreshes the current token, typically called when receiving a 401 response
    /// - Throws: An error if the token refresh fails
    func refreshToken() async throws
    
    /// Indicates whether the token service is currently authenticated
    var isAuthenticated: Bool { get async }
}

extension WebPark {
    var urlSession: URLSession { URLSession.shared }
    
    // Synchronous version for backward compatibility (mainly for tests)
    internal func createRequest(_ method: String,
                                endpoint: String,
                                queryItems: [URLQueryItem] = [],
                                isJSON: Bool = false) throws -> URLRequest? {
        
        // Construct the full URL string
        let fullURLString = self.baseURL + endpoint
        
        // Validate this is a proper HTTP/HTTPS URL since this is an HTTP library
        guard isValidHTTPURL(fullURLString) else {
            throw WebParkError.unableToMakeURL
        }
        
        // Create URLComponents for query parameter handling
        guard let urlComponents = URLComponents(string: fullURLString) else {
            throw WebParkError.unableToMakeURL
        }
        
        var finalComponents = urlComponents
        if queryItems.hasItems {
            finalComponents.queryItems = queryItems
        }
        
        guard let url = finalComponents.url else { 
            throw WebParkError.unableToMakeURL
        }
        
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
    
    // Async version for production use with async token services
    internal func createRequestAsync(_ method: String,
                                endpoint: String,
                                queryItems: [URLQueryItem] = [],
                                isJSON: Bool = false) async throws -> URLRequest? {
        
        // Construct the full URL string
        let fullURLString = self.baseURL + endpoint
        
        // Validate this is a proper HTTP/HTTPS URL since this is an HTTP library
        guard isValidHTTPURL(fullURLString) else {
            throw WebParkError.unableToMakeURL
        }
        
        // Create URLComponents for query parameter handling
        guard let urlComponents = URLComponents(string: fullURLString) else {
            throw WebParkError.unableToMakeURL
        }
        
        var finalComponents = urlComponents
        if queryItems.hasItems {
            finalComponents.queryItems = queryItems
        }
        
        guard let url = finalComponents.url else { 
            throw WebParkError.unableToMakeURL
        }
        
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
    
    /// Validates that a string represents a valid HTTP or HTTPS URL
    /// This is stricter than URL(string:) and ensures proper web URLs for HTTP requests
    private func isValidHTTPURL(_ urlString: String) -> Bool {
        // Check for invalid characters that shouldn't be in URLs (spaces, emojis, etc.)
        let invalidCharacters = CharacterSet(charactersIn: " \t\n\r\u{00A0}🚀🎉") // Common invalid chars including non-breaking space and emojis
        if urlString.rangeOfCharacter(from: invalidCharacters) != nil {
            return false
        }
        
        // Try to create URLComponents first
        guard let components = URLComponents(string: urlString) else {
            return false
        }
        
        // Ensure we have a valid scheme (http or https)
        guard let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return false
        }
        
        // Ensure we have a host
        guard let host = components.host, !host.isEmpty else {
            return false
        }
        
        // Verify we can create a valid URL from components
        guard let url = components.url else {
            return false
        }
        
        // Final validation: ensure the URL's absoluteString matches reasonable expectations
        // This catches edge cases where URLComponents might be too lenient
        let absoluteString = url.absoluteString
        return absoluteString.hasPrefix("http://") || absoluteString.hasPrefix("https://")
    }    
}

public enum WebParkError: Error, Equatable, CustomStringConvertible {
    case unableToMakeURL
    case unableToMakeRequest
    case decodeFailure(underlying: String)
    case unableToMakeAuthdRequest
    case encodeFailure(underlying: String)
    
    public var description: String {
        switch self {
        case .unableToMakeURL:
            return "Unable to create URL from provided base URL and endpoint"
        case .unableToMakeRequest:
            return "Unable to create URLRequest"
        case .decodeFailure(let underlying):
            return "Failed to decode response: \(underlying)"
        case .unableToMakeAuthdRequest:
            return "Unable to create authenticated request"
        case .encodeFailure(let underlying):
            return "Failed to encode request body: \(underlying)"
        }
    }
    
    public static func == (lhs: WebParkError, rhs: WebParkError) -> Bool {
        switch (lhs, rhs) {
        case (.unableToMakeURL, .unableToMakeURL),
             (.unableToMakeRequest, .unableToMakeRequest),
             (.unableToMakeAuthdRequest, .unableToMakeAuthdRequest):
            return true
        case (.decodeFailure(let lhsUnderlying), .decodeFailure(let rhsUnderlying)):
            return lhsUnderlying == rhsUnderlying
        case (.encodeFailure(let lhsUnderlying), .encodeFailure(let rhsUnderlying)):
            return lhsUnderlying == rhsUnderlying
        default:
            return false
        }
    }
}

public enum ErrorResponseCode: Int, Sendable, CaseIterable {
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case conflict = 409
    case unprocessableEntity = 422
    case tooManyRequests = 429
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    
    case unhandledResponseCode = 0
    
    /// A human-readable description of the HTTP error
    public var description: String {
        switch self {
        case .badRequest: return "Bad Request"
        case .unauthorized: return "Unauthorized"
        case .forbidden: return "Forbidden"
        case .notFound: return "Not Found"
        case .methodNotAllowed: return "Method Not Allowed"
        case .conflict: return "Conflict"
        case .unprocessableEntity: return "Unprocessable Entity"
        case .tooManyRequests: return "Too Many Requests"
        case .internalServerError: return "Internal Server Error"
        case .notImplemented: return "Not Implemented"
        case .badGateway: return "Bad Gateway"
        case .serviceUnavailable: return "Service Unavailable"
        case .gatewayTimeout: return "Gateway Timeout"
        case .unhandledResponseCode: return "Unhandled Response Code"
        }
    }
}

public struct WebParkHttpError: Error, Equatable, CustomStringConvertible {
    public let httpError: ErrorResponseCode
    public let statusCode: Int
    
    public init(_ statusCode: Int) {
        self.statusCode = statusCode
        self.httpError = ErrorResponseCode(rawValue: statusCode) ?? .unhandledResponseCode
    }
    
    public var description: String {
        return "HTTP \(statusCode): \(httpError.description)"
    }
    
    public var localizedDescription: String {
        return description
    }
}

