//
//  ParserProtocol.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

protocol Request{}

protocol ParserDelegate {
    func finishedParsingRequest(request: Request)
}

protocol Parser {
    var delegate: ParserDelegate? { get set }
    
    func resumeSocketReading(socket: GCDAsyncSocket)
    func parseData(socket: GCDAsyncSocket, data: NSData, tag: Int)
}