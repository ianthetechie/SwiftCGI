//
//  Blog.swift
//  SwiftCGI Demo
//
//  Created by Ian Wagner on 3/16/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import SwiftCGI

let blogRootHandler: RequestHandler = { request in
    var extraGreeting = ""
    
    return HTTPResponse(status: .OK, contentType: .TextPlain, body: "Welcome to my blog!")
}
