import XCTest
@testable import WebLeopard

public struct lSut : WebLeopard {
    public var baseURL: String
    public var token: String
}

final class WebLeopardTests: XCTestCase {
    func test__createRequest__given_valid_request__returns_request() throws {
        let sut = lSut(baseURL: "http://google.com/", token: "")
        
        let result = try sut.createRequest("GET", endpoint: "foo")
        
        XCTAssertNotNil(result)
    }
}
