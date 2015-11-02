//
//  FCGIParser.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

class FCGIBackend {
    private var currentRequests: [String: FCGIRequest] = [:]
    private var recordContext: [GCDAsyncSocket: FCGIRecordType] = [:]
    internal var paramsAvailableHandler: (Request -> Void)?
    private let defaultSendStream = FCGIOutputStream.Stdout
    var delegate: BackendDelegate?
    
    init() {}
    
    func handleRecord(record: FCGIRecordType, fromSocket socket: GCDAsyncSocket) {
        let globalRequestID = "\(record.requestID)-\(socket.connectedPort)"
        
        // TODO: Guards to handle early exits in odd cases like malformed data; I don't like all of
        // the forced unwrapping going on here right now...
        
        // Switch on record.type, since types can be mapped 1:1 to an FCGIRecord
        // subclass. This allows for a much cleaner chunk of code than a handful
        // of if/else ifs chained together, and allows the compiler to check that
        // we have covered all cases
        switch record.kind {
        case .BeginRequest:
            guard let record = record as? BeginRequestRecord else {
                fatalError("Invalid record type.")
            }
            
            let request = FCGIRequest(record: record)
            request.socket = socket
            
            currentRequests[globalRequestID] = request
            
            socket.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout, tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
        case .Params:
            let maybeRequest = currentRequests[globalRequestID]
            
            if let request = maybeRequest {
                guard let record = record as? ParamsRecord else {
                    fatalError("Invalid record type.")
                }
                
                if let params = record.params {
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
            let maybeRequest = currentRequests[globalRequestID]
            
            if let request = maybeRequest {
                if request.streamData == nil {
                    request.streamData = NSMutableData(capacity: 65536)
                }
                
                guard let record = record as? ByteStreamRecord else {
                    fatalError("Invalid record type.")
                }
                
                if let recordData = record.rawData {
                    request.streamData!.appendData(recordData)
                } else {
                    delegate?.finishedParsingRequest(request)
                    
                    currentRequests.removeValueForKey(globalRequestID)
                }
            } else {
                NSLog("WARNING: handleRecord called for invalid requestID")
            }
        default:
            // TODO: Throw proper error here and catch in server
            fatalError("ERROR: handleRecord called with an invalid FCGIRecord type")
        }
    }
}

extension FCGIBackend: Backend {
    func startReadingFromSocket(sock: GCDAsyncSocket) {
        sock.readDataToLength(FCGIRecordHeaderLength, withTimeout: FCGITimeout,
            tag: FCGISocketTag.AwaitingHeaderTag.rawValue)
    }
    
    func processData(sock: GCDAsyncSocket, data: NSData, tag: Int) {
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
                    // TODO: throw here and catch in server
                    NSLog("ERROR: Unable to construct request record")
                    sock.disconnect()
                }
            case .AwaitingContentAndPaddingTag:
                if var record = recordContext[sock] {
                    record.processContentData(data)
                    handleRecord(record, fromSocket: sock)
                } else {
                    NSLog("ERROR: Case .AwaitingContentAndPaddingTag hit with no context")
                }
            }
        } else {
            // TODO: throw here and catch in server
            NSLog("ERROR: Unknown socket tag")
            sock.disconnect()
        }
    }
    
    func cleanUp(sock: GCDAsyncSocket) {
        recordContext[sock] = nil
    }
    
    func sendResponse(request: Request, response: HTTPResponse) -> Bool {
        guard let req = request as? FCGIRequest else {
            fatalError("Could not convert request to FCGIRequest")
        }
        
        guard let sock = request.socket else {
            NSLog("ERROR: No socket for request")
            return false
        }
        
        guard let streamType = FCGIRecordKind(rawValue: defaultSendStream.rawValue) else {
            NSLog("ERROR: invalid stream type")
            return false
        }
        
        guard let data = response.responseData else {
            NSLog("No response data")
            return true
        }
        
        let remainingData = data.mutableCopy() as! NSMutableData
        while remainingData.length > 0 {
            let chunk = remainingData.subdataWithRange(NSMakeRange(0, min(remainingData.length, 65535)))
            let outRecord = ByteStreamRecord(version: req.record.version, requestID: req.record.requestID, contentLength: UInt16(chunk.length), paddingLength: 0, kind: streamType, rawData: chunk)
            
            sock.writeData(outRecord.fcgiPacketData, withTimeout: FCGITimeout, tag: 0)
            
            // Remove the data we just sent from the buffer
            remainingData.replaceBytesInRange(NSMakeRange(0, chunk.length), withBytes: nil, length: 0)
        }
        
        let termRecord = ByteStreamRecord(version: req.record.version, requestID: req.record.requestID, contentLength: 0, paddingLength: 0, kind: streamType)
        sock.writeData(termRecord.fcgiPacketData, withTimeout: FCGITimeout, tag: 0)
        
        return true
    }
}