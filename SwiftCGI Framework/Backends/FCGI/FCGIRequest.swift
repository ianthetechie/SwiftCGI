//
//  Request.swift
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

let FCGIRecordHeaderLength: UInt = 8
let FCGITimeout: NSTimeInterval = 5

public class FCGIRequest {
    let record: BeginRequestRecord
    let keepConnection: Bool
    
    public internal(set) var params: RequestParams = [:]  // Set externally and never reset to nil thereafter
    
    private var _cookies: [String: String]?
    
    public var socket: GCDAsyncSocket?     // Set externally by the server
    public var streamData: NSMutableData?
    // TODO: actually set the headers
    public var headers: [String: String]?
    
    init(record: BeginRequestRecord) {
        self.record = record
        keepConnection = record.flags?.contains(.KeepConnection) ?? false
    }
    
    // FCGI-specific implementation
    private func finishWithProtocolStatus(protocolStatus: FCGIProtocolStatus, andApplicationStatus applicationStatus: FCGIApplicationStatus) -> Bool {
        guard let sock = socket else {
            NSLog("ERROR: No socket for request")
            return false
        }
        
        let outRecord = EndRequestRecord(version: record.version, requestID: record.requestID, paddingLength: 0, protocolStatus: protocolStatus, applicationStatus: applicationStatus)
        sock.writeData(outRecord.fcgiPacketData, withTimeout: 5, tag: 0)
        
        if keepConnection {
            sock.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
        } else {
            sock.disconnectAfterWriting()
        }
        
        return true
    }
    
}

extension FCGIRequest: Request {
    
    public var path: String {
        guard let uri = params["REQUEST_URI"] else {
            fatalError("Encountered reques that was missing a path")
        }
        return uri
    }
    
    public func finish(status: RequestCompletionStatus) {
        switch status {
        case .Complete:
            finishWithProtocolStatus(.RequestComplete, andApplicationStatus: 0)
        }
    }
    
    public var cookies: [String: String]? {
        get {
            if _cookies == nil {
                if let cookieString = params["HTTP_COOKIE"] {
                    var result: [String: String] = [:]
                    let cookieDefinitions = cookieString.componentsSeparatedByString("; ")
                    for cookie in cookieDefinitions {
                        let cookieDef = cookie.componentsSeparatedByString("=")
                        result[cookieDef[0]] = cookieDef[1]
                    }
                    _cookies = result
                }
            }
            return _cookies
        }
        set {
            _cookies = newValue
        }
    }
    
    public var method: HTTPMethod {
        guard let requestMethod = params["REQUEST_METHOD"] else {
            fatalError("No REQUEST_METHOD found in the FCGI request params.")
        }
        
        guard let meth = HTTPMethod(rawValue: requestMethod) else {
            fatalError("Invalid HTTP method specified in REQUEST_METHOD.")
        }
        
        return meth
    }
    
}
