//
//  File.swift
//  
//
//  Created by Daniel Giralte on 9/14/23.
//

// thanks, Dave Delong
// https://davedelong.com/blog/2020/07/03/http-in-swift-part-5-testing-and-mocking/

import Foundation
import WebPark

public struct HTTPMethod: Hashable {
    public static let get = HTTPMethod(rawValue: "GET")
    public static let post = HTTPMethod(rawValue: "POST")
    public static let put = HTTPMethod(rawValue: "PUT")
    public static let delete = HTTPMethod(rawValue: "DELETE")

    public let rawValue: String
}

public struct HTTPRequest {
    private var urlComponents = URLComponents()
    public var method: HTTPMethod = .get // the struct we previously defined
    public var headers: [String: String] = [:]
    public var body: HTTPBody?
    public var url: URL?

    public init() {
        urlComponents.scheme = "https"
    }
}

public extension HTTPRequest {
    var scheme: String { urlComponents.scheme ?? "https" }
    
    var host: String? {
        get { urlComponents.host }
        set { urlComponents.host = newValue }
    }
    
    var path: String {
        get { urlComponents.path }
        set { urlComponents.path = newValue }
    }
}

public protocol HTTPBody {
    var isEmpty: Bool { get }
    var additionalHeaders: [String: String] { get }
    func encode() throws -> Data
}

extension HTTPBody {
    public var isEmpty: Bool { return false }
    public var additionalHeaders: [String: String] { return [:] }
}

public struct DataBody: HTTPBody {
    private let data: Data
    
    public var isEmpty: Bool { data.isEmpty }
    public var additionalHeaders: [String: String]
    
    public init(_ data: Data, additionalHeaders: [String: String] = [:]) {
        self.data = data
        self.additionalHeaders = additionalHeaders
    }
    
    public func encode() throws -> Data { data }
}

public struct JSONBody: HTTPBody {
    public let isEmpty: Bool = false
    public var additionalHeaders = [
        "Content-Type": "application/json; charset=utf-8"
    ]
    
    private let encodeF: () throws -> Data
    
    public init<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) {
        self.encodeF = { try encoder.encode(value) }
    }
    
    public func encode() throws -> Data { return Data() }
}

public struct FormBody: HTTPBody {
    public var isEmpty: Bool { values.isEmpty }
    public let additionalHeaders = [
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    ]
    
    private let values: [URLQueryItem]
    
    public init(_ values: [URLQueryItem]) {
        self.values = values
    }
    
    public init(_ values: [String: String]) {
        let queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        self.init(queryItems)
    }
    
    public func encode() throws -> Data {
        let pieces = values.map(self.urlEncode)
        let bodyString = pieces.joined(separator: "&")
        return Data(bodyString.utf8)
    }

    private func urlEncode(_ queryItem: URLQueryItem) -> String {
        let name = urlEncode(queryItem.name)
        let value = urlEncode(queryItem.value ?? "")
        return "\(name)=\(value)"
    }

    private func urlEncode(_ string: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
    }
}

public struct HTTPResponse {
    public let request: HTTPRequest
    private let response: HTTPURLResponse
    public let body: Data?
    
    public var status: ErrorResponseCode {
        // A struct of similar construction to HTTPMethod
        ErrorResponseCode(rawValue: response.statusCode)  ?? .notImplemented
    }

    public var message: String {
        HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }

    public var headers: [AnyHashable: Any] { response.allHeaderFields }
}

public typealias HTTPResult = Result<HTTPResponse, HTTPError>

public struct HTTPError: Error {
    /// The high-level classification of this error
    public let code: Code

    /// The HTTPRequest that resulted in this error
    public let request: HTTPRequest

    /// Any HTTPResponse (partial or otherwise) that we might have
    public let response: HTTPResponse?

    /// If we have more information about the error that caused this, stash it here
    public let underlyingError: Error?

    public enum Code {
        case invalidRequest     // the HTTPRequest could not be turned into a URLRequest
        case cannotConnect      // some sort of connectivity problem
        case cancelled          // the user cancelled the request
        case insecureConnection // couldn't establish a secure connection to the server
        case invalidResponse    // the system did not receive a valid HTTP response
        case unknown            // we have no idea what the problem is
    }
}

protocol HTTPLoading {
    func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void)
}

extension URLSession: HTTPLoading {
    public func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void) {
        guard let url = request.url else {
            // we couldn't construct a proper URL out of the request's URLComponents
            completion(.failure(HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)))
            return
        }
        
        // construct the URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        // copy over any custom HTTP headers
        for (header, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: header)
        }
        
        if let body = request.body {
            if body.isEmpty == false {
                // if our body defines additional headers, add them
                for (header, value) in body.additionalHeaders {
                    urlRequest.addValue(value, forHTTPHeaderField: header)
                }
                
                // attempt to retrieve the body data
                do {
                    urlRequest.httpBody = try body.encode()
                } catch {
                    // something went wrong creating the body; stop and report back
                    completion(.failure(HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)))
                    return
                }
            }
        }
        
        let dataTask = self.dataTask(with: urlRequest) { (data, response, error) in
            // construct a Result<HTTPResponse, HTTPError> out of the triplet of data, url response, and url error
            let result = HTTPResult(request: request, responseData: data, response: response, error: error)
            completion(result)
        }
        
        // off we go!
        dataTask.resume()
    }
}
