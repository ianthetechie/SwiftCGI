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


// MARK: Main server class

// NOTE: This class muse inherit from NSObject; otherwise the Obj-C code for
// GCDAsyncSocket will somehow not be able to store a reference to the delegate
// (it will remain nil and no error will be logged).
public class FCGIServer: NSObject, GCDAsyncSocketDelegate {
    // MARK: Properties
    
    public let port: UInt16
    public var paramsAvailableHandler: (Request -> Void)?
    public var requestRouter: Router
//    public var requestHandler: FCGIRequestHandler
    
    let delegateQueue: dispatch_queue_t
    var recordContext: [GCDAsyncSocket: FCGIRecord] = [:]
    private lazy var listener: GCDAsyncSocket = {
        GCDAsyncSocket(delegate: self, delegateQueue: self.delegateQueue)
    }()
    
    private var currentRequests: [String: FCGIRequest] = [:]
    private var activeSockets: Set<GCDAsyncSocket> = []
    
    private var registeredPreware: [RequestPrewareHandler] = []
    private var registeredMiddleware: [RequestMiddlewareHandler] = []
    private var registeredPostware: [RequestPostwareHandler] = []
    private let httpParser = HTTPParser()
    
    // MARK: Init
    
    public init(port: UInt16, requestRouter: Router) {
        self.port = port
        self.requestRouter = requestRouter
        
        delegateQueue = dispatch_queue_create("SocketAcceptQueue", DISPATCH_QUEUE_SERIAL)
    }
    
    
    // MARK: Instance methods
    
    public func start() throws {
        try listener.acceptOnPort(port)
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
            
            if var request = maybeRequest {
                if request.streamData == nil {
                    request.streamData = NSMutableData(capacity: 65536)
                }
                
                if let recordData = (record as! ByteStreamRecord).rawData {
                    request.streamData!.appendData(recordData)
                } else {
                    // TODO: Future - when Swift gets exception handling, wrap this
                    // TODO: Refactor this into a separate method
                    for handler in registeredPreware {
                        request = handler(request) as! FCGIRequest  // Because we can't correctly force compiler type checking without generic typealiases
                    }
                    
                    if let requestHandler = requestRouter.route(request.path) {
                        if var response = requestHandler(request) {
                            for handler in registeredMiddleware {
                                response = handler(request, response)
                            }
                            
                            if let responseData = response.responseData {
                                request.writeResponseData(responseData, toStream: FCGIOutputStream.Stdout)
                            }
                            
                            request.finish(.Complete)
                            
                            for handler in registeredPostware {
                                handler(request, response)
                            }
                        } else {
                            request.finish(.Complete)
                            
                            for handler in registeredPostware {
                                handler(request, nil)
                            }
                        }
                    }
                    
                    if let sock = request.socket {
                        recordContext[sock] = nil
                    }
                    
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
    
    
    // MARK: Pre/middle/postware registration
    
    public func registerPrewareHandler(handler: RequestPrewareHandler) -> Void {
        registeredPreware.append(handler)
    }
    
    public func registerMiddlewareHandler(handler: RequestMiddlewareHandler) -> Void {
        registeredMiddleware.append(handler)
    }
    
    public func registerPostwareHandler(handler: RequestPostwareHandler) -> Void {
        registeredPostware.append(handler)
    }
    
    
    // MARK: GCDAsyncSocketDelegate methods
    
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        activeSockets.insert(newSocket)
        
        // Looks like a leak, but isn't.
        let acceptedSocketQueue = dispatch_queue_create("SocketAcceptQueue-\(newSocket.connectedPort)", DISPATCH_QUEUE_SERIAL)
        newSocket.delegateQueue = acceptedSocketQueue
        
        if DEVSERVER {
            newSocket.readDataToData("\r\n".dataUsingEncoding(NSUTF8StringEncoding), withTimeout: 1000, tag: 0)
        }
        else {
            newSocket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout,
                tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
        }
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket?, withError err: NSError!) {
        if let sock = sock {
            recordContext[sock] = nil
            activeSockets.remove(sock)
        } else {
            NSLog("WARNING: nil sock disconnect")
        }
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if DEVSERVER {
            print(NSString(data: data, encoding: NSUTF8StringEncoding)!)
            httpParser.parseDataChunk(data)
            sock.readDataWithTimeout(1000, tag: 0)
        }
        else {
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
    }
}
