//
//  HTTPTests.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/8/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import XCTest

class HTTPTests: XCTestCase {
    func testHTTPResponse() {
        let status = HTTPStatus.OK
        let contentType = ContentType.TextHTML
        let body = "안녕하세요, Swifter!"
        let okResponse = HTTPResponse(body: body)
        
        XCTAssertEqual(okResponse.status, status, "Incorrect default HTTPStatus")
        XCTAssertEqual(okResponse.contentType, contentType, "Incorrect default content type")
        XCTAssertEqual(okResponse.contentLength, 25, "Incorrect content length computation")
        XCTAssertEqual(okResponse.body, body, "The request body is inexplicably different than its initial value")
        XCTAssertEqual(okResponse.headerString, "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 25\r\n\r\n", "The request header is not being properly generated")
        
        let otherOKResponse = HTTPResponse(status: status, contentType: contentType, body: body)
        XCTAssertEqual(okResponse.status, otherOKResponse.status, "Incorrect default HTTPStatus")
        XCTAssertEqual(okResponse.contentType, otherOKResponse.contentType, "Incorrect default content type")
        XCTAssertEqual(okResponse.body, otherOKResponse.body, "The request body is inexplicably different than its initial value")
    }
}
