//
//  HTTPBackend.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/21/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

extension Dictionary where Value : Equatable {
    func allKeysForValue(val : Value) -> [Key] {
//        return self.filter { $1 == val }.map { $0.0 }
        return self.flatMap({ (key, value) -> Key? in
            return value == val ? key : nil
        })
    }
}

enum RequestProcess: Int {
    case Started = 0
    case Processing = 1
    case Finished = 2
}

protocol EmbeddedHTTPBackendDelegate {
    func finishedRequestConstruction(parser: HTTPParser)
}

class EmbeddedHTTPBackend {
    let readSize: UInt = 65536
    let endOfLine: NSData = "\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
    var delegate: BackendDelegate?
    var currentRequests: [GCDAsyncSocket: HTTPParser] = [:]
    
    init() {}
}

extension EmbeddedHTTPBackend: Backend {
    func processData(sock: GCDAsyncSocket, data: NSData, tag: Int) {
        if let parser = currentRequests[sock] {
            parser.parseData(data)
            continueReadingFromSocket(sock)
        }
    }
    
    func startReadingFromSocket(sock: GCDAsyncSocket) {
        // Create a new parser and request data storage
        let newParser = HTTPParser()
        newParser.delegate = self
        currentRequests[sock] = newParser
        sock.readDataToData(endOfLine, withTimeout: 1000, tag: RequestProcess.Started.rawValue)
    }
    
    func continueReadingFromSocket(sock: GCDAsyncSocket) {
        sock.readDataWithTimeout(1000, tag: RequestProcess.Processing.rawValue)
    }
    
    func cleanUp(sock: GCDAsyncSocket) {
        currentRequests[sock] = nil
    }
    
    func sendResponse(request: Request, response: HTTPResponse) -> Bool {
        guard let sock = request.socket else {
            NSLog("ERROR: No socket for request")
            return false
        }
        
        guard let data = response.responseData else {
            NSLog("No response data")
            return true
        }
        
        let remainingData = data.mutableCopy() as! NSMutableData
        while remainingData.length > 0 {
            let chunk = remainingData.subdataWithRange(NSMakeRange(0, min(remainingData.length, 65535)))
//            print(chunk)
            sock.writeData(chunk, withTimeout: 1000, tag: 0)
            
            // Remove the data we just sent from the buffer
            remainingData.replaceBytesInRange(NSMakeRange(0, chunk.length), withBytes: nil, length: 0)
        }
        
        return true
    }
}

extension EmbeddedHTTPBackend: EmbeddedHTTPBackendDelegate {
    func finishedRequestConstruction(parser: HTTPParser) {
        var req = HTTPRequest(pRequest: parser.data)
        
        // FIXME: What is this abomination?!
        guard let sock = currentRequests.allKeysForValue(parser).first else {
            fatalError("Could not find associated socket")
        }
        req.socket = sock
        delegate?.finishedParsingRequest(req)
    }
}