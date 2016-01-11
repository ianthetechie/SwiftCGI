//
//  HTTPTests.swift
//  SwiftCGI
//
//  Copyright (c) 2014, Ian Wagner
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that thefollowing conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

import XCTest

class HTTPTests: XCTestCase {
    func testHTTPResponse() {
        let status = HTTPStatus.OK
        let contentType = HTTPContentType.TextPlain(.UTF8)
        let body = "안녕하세요, Swifter!"
        let okResponse = HTTPResponse(body: body)
        
        XCTAssertEqual(okResponse.status, status, "Incorrect default HTTPStatus")
        XCTAssertEqual(okResponse.contentType, contentType, "Incorrect default content type")
        XCTAssertEqual(okResponse.contentLength, 25, "Incorrect content length computation")
        XCTAssertEqual(okResponse.body, body, "The request body is inexplicably different than its initial value")
        XCTAssertEqual(okResponse.responseData, "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 25\r\n\r\n\(body)".dataUsingEncoding(NSUTF8StringEncoding), "The request header is not being properly generated")
        
        let otherOKResponse = HTTPResponse(status: status, contentType: contentType, body: body)
        XCTAssertEqual(okResponse.status, otherOKResponse.status, "Incorrect default HTTPStatus")
        XCTAssertEqual(okResponse.contentType, otherOKResponse.contentType, "Incorrect default content type")
        XCTAssertEqual(okResponse.body, otherOKResponse.body, "The request body is inexplicably different than its initial value")
    }
}
