import XCTest
@testable import WebPark

public struct lSut : WebPark {
    public func refreshToken() {
        
    }
    
    public var baseURL: String
    public var token: String
}

final class WebParkTests: XCTestCase {
    func test__createRequest__given_valid_request__returns_request() throws {
        let sut = lSut(baseURL: "http://google.com/", token: "")
        
        let result = try sut.createRequest("GET", endpoint: "foo")
        
        XCTAssertNotNil(result)
    }
    
    
}
