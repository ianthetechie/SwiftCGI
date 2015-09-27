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
public class FCGIServer: NSObject, GCDAsyncSocketDelegate, ParserDelegate {
    // MARK: Properties
    
    public let port: UInt16
    public var requestRouter: Router
//    public var requestHandler: FCGIRequestHandler
    
    let delegateQueue: dispatch_queue_t
    private lazy var listener: GCDAsyncSocket = {
        GCDAsyncSocket(delegate: self, delegateQueue: self.delegateQueue)
    }()
    
    
    private var activeSockets: Set<GCDAsyncSocket> = []
    
    private var registeredPreware: [RequestPrewareHandler] = []
    private var registeredMiddleware: [RequestMiddlewareHandler] = []
    private var registeredPostware: [RequestPostwareHandler] = []
    private let parser: Parser;
    
    // MARK: Init
    
    public init(port: UInt16, requestRouter: Router) {
        if DEVSERVER {
            parser = HTTPParser()
        } else {
            parser = FCGIParser()
        }
        
        self.port = port
        self.requestRouter = requestRouter
        
        delegateQueue = dispatch_queue_create("SocketAcceptQueue", DISPATCH_QUEUE_SERIAL)
    }
    
    
    // MARK: Instance methods
    
    public func start() throws {
        try listener.acceptOnPort(port)
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
        
        parser.resumeSocketReading(newSocket)
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket?, withError err: NSError!) {
        if let sock = sock {
            parser.socketDisconnect(sock)
            activeSockets.remove(sock)
        } else {
            NSLog("WARNING: nil sock disconnect")
        }
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        print(NSString(data: data, encoding: NSUTF8StringEncoding)!)
        parser.parseData(sock, data: data, tag: tag)
    }
    
    func finishedParsingRequest(request: Request) {
        var req = request as! FCGIRequest
        // TODO: Future - when Swift gets exception handling, wrap this
        // TODO: Refactor this into a separate method
        for handler in registeredPreware {
            req = handler(request) as! FCGIRequest  // Because we can't correctly force compiler type checking without generic typealiases
        }
        
        if let requestHandler = requestRouter.route(req.path) {
            if var response = requestHandler(req) {
                for handler in registeredMiddleware {
                    response = handler(req, response)
                }
                
                if let responseData = response.responseData {
                    req.writeResponseData(responseData, toStream: FCGIOutputStream.Stdout)
                }
                
                req.finish(.Complete)
                
                for handler in registeredPostware {
                    handler(req, response)
                }
            } else {
                req.finish(.Complete)
                
                for handler in registeredPostware {
                    handler(req, nil)
                }
            }
        }
        
        if let sock = request.socket {
            parser.socketDisconnect(sock)
        }
    }
}
