//
//  Server.swift
//  SwiftCGI
//
//  Copyright (c) 2014, Ian Wagner
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that thefollowing conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

// NOTE: This class muse inherit from NSObject; otherwise the Obj-C code for
// GCDAsyncSocket will somehow not be able to store a reference to the delegate
// (it will remain nil and no error will be logged).
public class FCGIServer: NSObject, GCDAsyncSocketDelegate {
    // MARK: Properties
    
    public let port: UInt16
    public var paramsAvailableHandler: (FCGIRequest -> Void)?
    public var requestHandler: FCGIRequestHandler
    
    let delegateQueue: dispatch_queue_t
    var recordContext: [GCDAsyncSocket: FCGIRecord] = [:]
    private lazy var listener: GCDAsyncSocket = {
        GCDAsyncSocket(delegate: self, delegateQueue: self.delegateQueue)
    }()
    
    private var currentRequests: [String: FCGIRequest] = [:]
    
    
    // MARK: Init
    
    public init(port: UInt16, requestHandler: FCGIRequestHandler) {
        self.port = port
        self.requestHandler = requestHandler
        
        delegateQueue = dispatch_queue_create("SocketAcceptQueue", DISPATCH_QUEUE_SERIAL)
    }
    
    
    // MARK: Instance methods
    
    public func startWithError(errorPtr: NSErrorPointer) -> Bool {
        if listener.acceptOnPort(port, error: errorPtr) {
            return true
        } else {
            return false
        }
    }
    
    func handleRecord(record: FCGIRecord, fromSocket socket: GCDAsyncSocket) {
        let globalRequestID = "\(record.requestID)-\(socket.connectedPort)"
        
        // switch on record.type, since types can be mapped 1:1 to an FCGIRecord
        // subclass. This allows for a much cleaner chunk of code than a handful
        // of if/else ifs chained together, and allows the compiler to check that
        // we have covered all cases
        switch record.type {
        case .BeginRequest:
            let request = FCGIRequest(record: record as BeginRequestRecord)
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
                if let params = (record as ParamsRecord).params {
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
                
                if let recordData = (record as ByteStreamRecord).rawData {
                    request.streamData!.appendData(recordData)
                } else {
                    if var response = requestHandler(request) {
                        // Add the session cookie if necessary
                        if request.sessionID == nil {
                            request.generateNewSessionID()
                            response.setResponseHeader(.SetCookie([SessionIDCookieName: "\(request.sessionID!); Max-Age=86400"]))
                        }
                        
                        if let responseData = response.responseData {
                            request.writeData(responseData, toStream: FCGIOutputStream.Stdout)
                        }
                    }
                    
                    request.finishWithProtocolStatus(FCGIProtocolStatus.RequestComplete, andApplicationStatus: 0)
                    
                    recordContext[request.socket] = nil
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
    
    
    // MARK: GCDAsyncSocketDelegate methods
    
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        // Looks like a leak, but isn't.
        let acceptedSocketQueue = dispatch_queue_create("SocketAcceptQueue-\(newSocket.connectedPort)", DISPATCH_QUEUE_SERIAL)
        newSocket.delegateQueue = acceptedSocketQueue
        
        newSocket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        recordContext[sock] = nil
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if let socketTag = FCGISocketTag(rawValue: tag) {
            switch socketTag {
            case .AwaitingHeaderTag:
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
}

// Convenience funciton, since you really shouldn't have to manually construct
// a server instance and crap.
// NOTE: This was designed for a command-line app, but at the time of this
// writing, command-line apps + frameworks = a bomb. So... yeah... waiting
// for Apple to fix that.
public func runServerUntilKilled(port: UInt16 = 9000, #requestHandler: FCGIRequestHandler) {
    let server = FCGIServer(port: port, requestHandler: requestHandler)
    
    var err: NSError?
    server.startWithError(&err)
    
    if let error = err {
        println("Failed to start SwiftCGI server")
        println(err)
        exit(1)
    } else {
        println("Started SwiftCGI server on port \(server.port)")
        dispatch_main()
    }
}
