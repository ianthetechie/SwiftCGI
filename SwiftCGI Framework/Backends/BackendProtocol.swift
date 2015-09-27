//
//  BackendProtocol.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

protocol BackendDelegate {
    func finishedParsingRequest(request: Request)
}

protocol Backend {
    var delegate: BackendDelegate? { get set }
    
    func startReadingFromSocket(sock: GCDAsyncSocket)
    
    func processData(sock: GCDAsyncSocket, data: NSData, tag: Int)
    
    func cleanUp(sock: GCDAsyncSocket)
    
    func sendResponse(request: Request, response: HTTPResponse) -> Bool
}