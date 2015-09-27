//
//  ParserProtocol.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

protocol ParserDelegate {
    func finishedParsingRequest(request: Request)
}

protocol Parser {
    var delegate: ParserDelegate? { get set }
    
    func resumeSocketReading(sock: GCDAsyncSocket)
    func parseData(sock: GCDAsyncSocket, data: NSData, tag: Int)
    
    func socketDisconnect(sock: GCDAsyncSocket)
}