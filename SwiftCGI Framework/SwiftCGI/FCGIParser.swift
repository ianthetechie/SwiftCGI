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
    
    init() {}
    
    func resumeSocketReading(socket: GCDAsyncSocket) {
        
    }
    
    func parseData(socket: GCDAsyncSocket, data: NSData, tag: Int) {
        if let socketTag = FCGISocketTag(rawValue: tag) {
            switch socketTag {
            case .AwaitingHeaderTag:
                // Phase 1 of 2 possible phases; first, try to parse the header
                if let record = createRecordFromHeaderData(data) {
                    if record.contentLength == 0 {
                        // No content; handle the message
                        handleRecord(record, fromSocket: socket)
                    } else {
                        // Read additional content
                        recordContext[socket] = record
                        socket.readDataToLength(UInt(record.contentLength) + UInt(record.paddingLength), withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingContentAndPaddingTag.rawValue)
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
}