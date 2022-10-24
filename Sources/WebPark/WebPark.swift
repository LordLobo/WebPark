import Foundation

/// 
public protocol WebPark {
    var baseURL: String { get }
    
    // possible fix for token refresh - token service that catches 401s
    var token: String { get }
}

extension WebPark {
    
    func createRequest(_ method: String,
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
        
        if token.count > 0 {
            request = request.addingBearerAuthorization(token: token)
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

