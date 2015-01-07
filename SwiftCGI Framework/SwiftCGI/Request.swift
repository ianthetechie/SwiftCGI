//
//  Request.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/5/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

let FCGIRecordFixedLengthPartLength: UInt = 8
let FCGITimeout: NSTimeInterval = -1

public class FCGIRequest {
    let meta: BeginRequestMeta
    let keepConnection: Bool
    
    var params: FCGIRequestParams!  // Set externally and never reset to nil thereafter
    var socket: GCDAsyncSocket!     // Set externally by the server
    var streamData: NSMutableData?
    
    init(meta: BeginRequestMeta) {
        self.meta = meta
        keepConnection = meta.flags & FCGIRequestFlags.KeepConnection ? true : false
    }
    
    // WARNING: I think this will fail with data size > 64k
    public func writeData(data: NSData, toStream stream: FCGIOutputStream) -> Bool {
        if socket != nil {
            let outMeta = ByteStreamMeta(version: meta.version, requestID: meta.requestID, contentLength: UInt16(data.length), paddingLength: 0)
            outMeta.setRawData(data)
            if let streamType = FCGIMetaType(rawValue: stream.rawValue) {
                outMeta.type = streamType
                socket.writeData(outMeta.fcgiPacketData, withTimeout: FCGITimeout, tag: 0)
                return true
            }
        }
        
        NSLog("ERROR: No socket for request")
        return false
    }
    
    public func finishWithProtocolStatus(protocolStatus: FCGIProtocolStatus, andApplicationStatus applicationStatus: FCGIApplicationStatus) -> Bool {
        if socket != nil {
            let outMeta = EndRequestMeta(version: meta.version, requestID: meta.requestID, paddingLength: 0, protocolStatus: protocolStatus, applicationStatus: applicationStatus)
            socket.writeData(outMeta.fcgiPacketData, withTimeout: 5, tag: 0)
            
            if keepConnection {
                socket.readDataToLength(FCGIRecordFixedLengthPartLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
            } else {
                socket.disconnectAfterWriting()
            }
            
            return true
        } else {
            NSLog("ERROR: No socket for request")
            return false
        }
    }
}