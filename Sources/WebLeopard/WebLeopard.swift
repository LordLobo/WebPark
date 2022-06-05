import Foundation

/// 
public protocol WebLeopard {
    var baseURL: String { get }
    var token: String { get }
}

extension WebLeopard {
    
    func createRequest(_ method: String,
                              endpoint: String,
                              queryItems: [URLQueryItem] = [],
                              isJSON: Bool = false) throws -> URLRequest? {
        
        guard var urlComponents = URLComponents(string: self.baseURL + endpoint)
        else {
            throw WebLeopardError.unableToMakeURL
        }
        
        if queryItems.hasItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else { throw WebLeopardError.unableToMakeURL}
        
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

public enum WebLeopardError: Error {
    case unableToMakeURL
    case unableToMakeRequest
    case decodeFailure
    case unableToMakeAuthdRequest
    case encodeFailure
}

public enum ErrorResponseCodes: Int {
    case unauthorized = 401
    case notFound = 404
    case internalServerError = 500
    case notImplemented = 501
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    
    case unhandledResponseCode = 0
}

public class HttpError: Error {
    public var httpError: ErrorResponseCodes
    
    public init(_ withError: Int) {
        httpError = ErrorResponseCodes(rawValue: withError) ?? .unhandledResponseCode
    }
}

