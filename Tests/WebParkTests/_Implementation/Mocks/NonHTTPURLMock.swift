//
//  NonHTTPURLMock.swift
//
//
//  Replies with a bare `URLResponse` rather than an `HTTPURLResponse`, so that the
//  library's handling of a non-HTTP reply can be exercised.
//

import Foundation

class NonHTTPURLProtocolMock: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            self.client?.urlProtocolDidFinishLoading(self)
            return
        }

        // Deliberately not an HTTPURLResponse, so there is no status code to check.
        let response = URLResponse(url: url,
                                   mimeType: "application/json",
                                   expectedContentLength: 2,
                                   textEncodingName: nil)

        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: Data("{}".utf8))
        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // Required to be implemented. Do nothing here.
    }
}

func BuildNonHTTPURLSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [NonHTTPURLProtocolMock.self]

    return URLSession(configuration: configuration)
}
