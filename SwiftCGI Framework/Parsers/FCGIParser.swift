//
//  FCGIParser.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

class FCGIParser: Parser {
    var delegate: ParserDelegate?
    private var currentRequests: [String: FCGIRequest] = [:]
    private var recordContext: [GCDAsyncSocket: FCGIRecord] = [:]
    internal var paramsAvailableHandler: (Request -> Void)?
    
    init() {}
    
    func resumeSocketReading(sock: GCDAsyncSocket) {
        sock.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout,
            tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
    }
    
    func parseData(sock: GCDAsyncSocket, data: NSData, tag: Int) {
        if let socketTag = FCGISocketTag(rawValue: tag) {
            switch socketTag {
            case .AwaitingHeaderTag:
                // TODO: Clean up this
                // Phase 1 of 2 possible phases; first, try to parse the header
                if let record = createRecordFromHeaderData(data) {
                    if record.contentLength == 0 {
                        // No content; handle the message
                        handleRecord(record, fromSocket: sock)
                    } else {
                        // Read additional content
                        recordContext[sock] = record
                        sock.readDataToLength(UInt(record.contentLength) + UInt(record.paddingLength), withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingContentAndPaddingTag.rawValue)
                    }
                } else {
                    NSLog("ERROR: Unable to construct request record")
                    sock.disconnect()
                }
            case .AwaitingContentAndPaddingTag:
                if let record = recordContext[sock] {
                    record.processContentData(data)
                    handleRecord(record, fromSocket: sock)
                } else {
                    NSLog("ERROR: Case .AwaitingContentAndPaddingTag hit with no context")
                }
            }
        } else {
            NSLog("ERROR: Unknown socket tag")
            sock.disconnect()
        }
    }
    
    func socketDisconnect(sock: GCDAsyncSocket) {
        recordContext[sock] = nil
    }
    
    func handleRecord(record: FCGIRecord, fromSocket socket: GCDAsyncSocket) {
        let globalRequestID = "\(record.requestID)-\(socket.connectedPort)"
        
        // TODO: Guards to handle early exits in odd cases like malformed data; I don't like all of
        // the forced unwrapping going on here right now...
        
        // Switch on record.type, since types can be mapped 1:1 to an FCGIRecord
        // subclass. This allows for a much cleaner chunk of code than a handful
        // of if/else ifs chained together, and allows the compiler to check that
        // we have covered all cases
        switch record.type {
        case .BeginRequest:
            let request = FCGIRequest(record: record as! BeginRequestRecord)
            request.socket = socket
            
            objc_sync_enter(currentRequests)
            currentRequests[globalRequestID] = request
            objc_sync_exit(currentRequests)
            
            socket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
        case .Params:
            objc_sync_enter(currentRequests)
            let maybeRequest = currentRequests[globalRequestID]
            objc_sync_exit(currentRequests)
            
            if let request = maybeRequest {
                if let params = (record as! ParamsRecord).params {
                    if request._params == nil {
                        request._params = [:]
                    }
                    
                    // Copy the values into the request params dictionary
                    for key in params.keys {
                        request._params[key] = params[key]
                    }
                } else {
                    paramsAvailableHandler?(request)
                }
                
                socket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
            }
        case .Stdin:
            objc_sync_enter(currentRequests)
            let maybeRequest = currentRequests[globalRequestID]
            objc_sync_exit(currentRequests)
            
            if let request = maybeRequest {
                if request.streamData == nil {
                    request.streamData = NSMutableData(capacity: 65536)
                }
                
                if let recordData = (record as! ByteStreamRecord).rawData {
                    request.streamData!.appendData(recordData)
                } else {
                    delegate?.finishedParsingRequest(request)
                    
                    objc_sync_enter(currentRequests)
                    currentRequests.removeValueForKey(globalRequestID)
                    objc_sync_exit(currentRequests)
                }
            } else {
                NSLog("WARNING: handleRecord called for invalid requestID")
            }
        default:
            fatalError("ERROR: handleRecord called with an invalid FCGIRecord type")
        }
    }
}