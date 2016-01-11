//
//  RouterTests.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 11/23/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import XCTest

class RouterTests: XCTestCase {
    func testLoneRootRouter() {
        let rootHandler: RequestHandler? = { (req) -> HTTPResponse? in
            return HTTPResponse(body: "Root handler")
        }
        let rootRouter = Router(path: "/", handleWildcardChildren: true, withHandler: rootHandler)
        
        XCTAssertNotNil(rootRouter.route("/"), "bar")
        XCTAssertNil(rootRouter.route("/foo"), "bar")
    }
}
