//
//  MockURL.swift
//  
//
//  Created by Daniel Giralte on 5/29/24.
//

import Foundation

// special thanks to this gist https://gist.github.com/soujohnreis/7c86965efbbb2297d4db3f84027327c1
class URLProtocolMock: URLProtocol {
    /// Dictionary maps URLs to tuples of error, data, and response
    nonisolated(unsafe) private static var mockURLs: [URL: (error: Error?, data: Data?, response: HTTPURLResponse?)] = [:]
    private static let lock = NSLock()

    // Thread-safe APIs to mutate and read mocks
    static func setMock(_ entry: (error: Error?, data: Data?, response: HTTPURLResponse?), for url: URL) {
        lock.lock()
        mockURLs[url] = entry
        lock.unlock()
    }
    /// Set multiple mock entries at once. Each element is a pair of (URL, entry).
    static func setMock(_ entries: [(URL, (error: Error?, data: Data?, response: HTTPURLResponse?))]) {
        lock.lock()
        for (url, entry) in entries {
            mockURLs[url] = entry
        }
        lock.unlock()
    }

    static func removeAllMocks() {
        lock.lock()
        mockURLs.removeAll()
        lock.unlock()
    }

    static func mock(for url: URL) -> (error: Error?, data: Data?, response: HTTPURLResponse?)? {
        lock.lock()
        defer { lock.unlock() }
        return mockURLs[url]
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all types of requests
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Required to be implemented here. Just return what is passed
        return request
    }
    
    override func startLoading() {
        if let url = request.url {
            if let (error, data, response) = URLProtocolMock.mock(for: url) {
                // We have a mock response specified so return it.
                if let responseStrong = response {
                    self.client?.urlProtocol(self, didReceive: responseStrong, cacheStoragePolicy: .notAllowed)
                }
                
                // We have mocked data specified so return it.
                if let dataStrong = data {
                    self.client?.urlProtocol(self, didLoad: dataStrong)
                }
                
                // We have a mocked error so return it.
                if let errorStrong = error {
                    self.client?.urlProtocol(self, didFailWithError: errorStrong)
                }
            }
        }
        
        // Send the signal that we are done returning our mock response
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // Required to be implemented. Do nothing here.
    }
}

