//
//  main.swift
//  SwiftCGIDemo
//
//  Created by Ian Wagner on 1/6/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import SwiftCGI

let server = FCGIServer(port: 9000)

server.paramsAvailableHandler = { request in
    
}

server.stdinAvailableHandler = { request in
    if let response = ("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 25\r\n\r\n안녕하세요, Swifter!" as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
        request.writeData(response, toStream: FCGIOutputStream.Stdout)
    }
    
    request.finishWithProtocolStatus(FCGIProtocolStatus.RequestComplete, andApplicationStatus: 0)
}

println("Starting SwiftCGI Server")

var err: NSError?
server.startWithError(&err)

if let error = err {
    println(err)
    exit(1)
} else {
    dispatch_main()
}
