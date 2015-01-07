//
//  Server.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/5/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

// NOTE: This class muse inherit from NSObject; otherwise the Obj-C code for
// GCDAsyncSocket will somehow not be able to store a reference to the delegate
// (it will remain nil and no error will be logged).
public class FCGIServer: NSObject, GCDAsyncSocketDelegate {
    // MARK: Properties
    
    let port: UInt16
    public var paramsAvailableHandler: FCGIRequestHandler?
    public var stdinAvailableHandler: FCGIRequestHandler?
    
    let delegateQueue: dispatch_queue_t
    var metaContext: FCGIMeta?
    lazy var listener: GCDAsyncSocket = {
        GCDAsyncSocket(delegate: self, delegateQueue: self.delegateQueue)
    }()
    
    var isRunning = false
    
    private var connectedSockets: [GCDAsyncSocket] = []
    private var currentRequests: [String: FCGIRequest] = [:]
    
    
    // MARK: Init
    
    public init(port: UInt16) {
        self.port = port
        
        delegateQueue = dispatch_queue_create("SocketAcceptQueue", DISPATCH_QUEUE_SERIAL)
    }
    
    
    // MARK: Instance methods
    
    public func startWithError(errorPtr: NSErrorPointer) -> Bool {
        if listener.acceptOnPort(port, error: errorPtr) {
            isRunning = true
            return true
        } else {
            return false
        }
    }
    
    func handleMeta(meta: FCGIMeta, fromSocket socket: GCDAsyncSocket) {
        let globalRequestID = "\(meta.requestID)-\(socket.connectedPort)"
        
        
        // switch on meta.type, since types can be mapped 1:1 to an FCGIMeta
        // subclass. This allows for a much cleaner chunk of code than a handful
        // of if/else ifs chained together, and allows the compiler to check that
        // we have covered all cases
        switch meta.type {
        case .BeginRequest:
            let request = FCGIRequest(meta: meta as BeginRequestMeta)
            request.socket = socket
            
            objc_sync_enter(currentRequests)
            currentRequests[globalRequestID] = request
            objc_sync_exit(currentRequests)
            
            socket.readDataToLength(FCGIRecordFixedLengthPartLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
        case .Params:
            objc_sync_enter(currentRequests)
            let maybeRequest = currentRequests[globalRequestID]
            objc_sync_exit(currentRequests)
            
            if let request = maybeRequest {
                if let params = (meta as ParamsMeta).params {
                    if request.params == nil {
                        request.params = [:]
                    }
                    
                    // Copy the values into the request params dictionary
                    for key in params.keys {
                        request.params[key] = params[key]
                    }
                } else {
                    paramsAvailableHandler?(request)
                }
                
                socket.readDataToLength(FCGIRecordFixedLengthPartLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
            }
        case .Stdin:
            objc_sync_enter(currentRequests)
            let maybeRequest = currentRequests[globalRequestID]
            objc_sync_exit(currentRequests)
            
            if let request = maybeRequest {
                if request.streamData == nil {
                    request.streamData = NSMutableData(capacity: 65536)
                }
                
                if let metaData = (meta as ByteStreamMeta).rawData {
                    request.streamData!.appendData(metaData)
                }
                
                stdinAvailableHandler?(request)
                
                objc_sync_enter(currentRequests)
                currentRequests.removeValueForKey(globalRequestID)
                objc_sync_exit(currentRequests)
            } else {
                NSLog("WARNING: handleMeta called for invalid requestID")
            }
        default:
            fatalError("ERROR: handleMeta called with an invalid FCGIMeta type")
        }
    }
    
    
    // MARK: GCDAsyncSocketDelegate methods
    
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        // Looks like a leak, but isn't.
        let acceptedSocketQueue = dispatch_queue_create("SocketAcceptQueue-\(newSocket.connectedPort)", DISPATCH_QUEUE_SERIAL)
        newSocket.delegateQueue = acceptedSocketQueue
        
        objc_sync_enter(connectedSockets)
        connectedSockets.append(newSocket)
        objc_sync_exit(connectedSockets)
        
        newSocket.readDataToLength(FCGIRecordFixedLengthPartLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        objc_sync_enter(connectedSockets)
        for (var i = 0; i < connectedSockets.count; ++i) {
            if connectedSockets[i] == sock {
                connectedSockets.removeAtIndex(i)
                break
            }
        }
        objc_sync_exit(connectedSockets)
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if let socketTag = FCGISocketTag(rawValue: tag) {
            switch socketTag {
            case .AwaitingHeaderTag:
                // Phase 1 of 2 possible phases; first, try to parse the header
                if let meta = createMetaFromHeaderData(data) {
                    if meta.contentLength == 0 {
                        // No content; handle the message
                        handleMeta(meta, fromSocket: sock)
                    } else {
                        // Read additional content
                        metaContext = meta
                        sock.readDataToLength(UInt(meta.contentLength) + UInt(meta.paddingLength), withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingContentAndPaddingTag.rawValue)
                    }
                } else {
                    NSLog("ERROR: Unable to construct request meta")
                    sock.disconnect()
                }
            case .AwaitingContentAndPaddingTag:
                if let meta = metaContext {
                    meta.processContentData(data)
                    handleMeta(meta, fromSocket: sock)
                    metaContext = nil
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
