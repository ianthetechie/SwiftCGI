//
//  Meta.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/4/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

// MARK: Meta structs

// Base struct (should never be directly instantiated)
class FCGIMeta {
    // NOTE: As of this writing, the Swift compiler will throw an error
    // about uninitialized stored properties, due to the failable nature
    // of the initializer. This is of course rubbish, as there is no point
    // initializing stored properties when you know that construction has
    // failed early on, so these properties are marked as implicitly unwrapped
    // optionals... for now...
    let version: FCGIVersion!
    let requestID: FCGIRequestId!

    // A public getter exposes the private constant storage because certain types
    // of meta subclasses are used for incoming data (in which the content length
    // is known at instantiation), and others compute content length before
    // sending a packet.
    let _initContentLength: FCGIContentLength!
    var contentLength: FCGIContentLength { return _initContentLength }
    
    let paddingLength: FCGIPaddingLength!
    
    var type: FCGIMetaType { fatalError("Not Implemented") }
    
    var fcgiPacketData: NSData {
        var bytes = [UInt8](count: 8, repeatedValue: 0)
        bytes[0] = version.rawValue
        bytes[1] = type.rawValue
        
        let (msb, lsb) = requestID.decomposeBigEndian()
        bytes[2] = msb
        bytes[3] = lsb
        
        let bigEndianContentLength = CFSwapInt16HostToBig(contentLength)
        bytes[4] = UInt8(bigEndianContentLength & 0xFF) // MSB
        bytes[5] = UInt8(bigEndianContentLength >> 8)   // LSB
        
        bytes[6] = paddingLength
        
        return NSData(bytes: &bytes, length: 8)
    }
    
    init(version: FCGIVersion, requestID: FCGIRequestId, contentLength: FCGIContentLength, paddingLength: FCGIPaddingLength) {
        self.version = version
        self.requestID = requestID
        self._initContentLength = contentLength
        self.paddingLength = paddingLength
    }
    
     func processContentData(data: NSData) {
        fatalError("Not Implemented")
    }
}

// Begin request meta
class BeginRequestMeta: FCGIMeta {
    var role: FCGIRequestRole!
    var flags: FCGIRequestFlags!
    
    override var type: FCGIMetaType { return .BeginRequest }
    
    override func processContentData(data: NSData) {
        let rawRole = readUInt16FromBigEndianData(data, atIndex: 0)
        
        if let concreteRole = FCGIRequestRole(rawValue: rawRole) {
            role = concreteRole
            
            var rawFlags: FCGIRequestFlags.RawValue = 0
            data.getBytes(&rawFlags, range: NSMakeRange(2, 1))
            flags = FCGIRequestFlags(rawValue: rawFlags)
        }
    }
}

// End request meta
class EndRequestMeta: FCGIMeta {
    let applicationStatus: FCGIApplicationStatus
    let protocolStatus: FCGIProtocolStatus
    
    override var type: FCGIMetaType { return .EndRequest }
    override var contentLength: FCGIContentLength { return 8 }  // Fixed value for this type
    
    init(version: FCGIVersion, requestID: FCGIRequestId, paddingLength: FCGIPaddingLength, protocolStatus: FCGIProtocolStatus, applicationStatus: FCGIApplicationStatus) {
        self.applicationStatus = applicationStatus
        self.protocolStatus = protocolStatus
        
        super.init(version: version, requestID: requestID, contentLength: 0, paddingLength: paddingLength)
    }
    
    override var fcgiPacketData: NSData {
        let result = super.fcgiPacketData.mutableCopy() as NSMutableData
        
        var extraBytes = [UInt8](count: 8, repeatedValue: 0)
        
        let bigEndianApplicationStatus = CFSwapInt32HostToBig(applicationStatus)
        extraBytes[0] = UInt8((bigEndianApplicationStatus >> 0) & 0xFF)
        extraBytes[1] = UInt8((bigEndianApplicationStatus >> 8) & 0xFF)
        extraBytes[2] = UInt8((bigEndianApplicationStatus >> 16) & 0xFF)
        extraBytes[3] = UInt8((bigEndianApplicationStatus >> 24) & 0xFF)
        
        extraBytes[4] = protocolStatus.rawValue
        
        result.appendData(NSData(bytes: &extraBytes, length: 8))
        
        return result
    }
}

// Data meta
class ByteStreamMeta: FCGIMeta {
    private var _rawData: NSData?
    var rawData: NSData? { return _rawData }
    
    override var contentLength: FCGIContentLength { return FCGIContentLength(_rawData?.length ?? 0) }
    
    var _type: FCGIMetaType = .Stdin
    override var type: FCGIMetaType {
        get { return _type }
        set {
            switch newValue {
            case .Stdin, .Stdout, .Stderr:
                _type = newValue
            default:
                fatalError("ByteStreamMeta.type can only be .Stdin .Stdout or .Stderr")
            }
        }
    }
    
    override var fcgiPacketData: NSData {
        let result = super.fcgiPacketData.mutableCopy() as NSMutableData
        if let data = _rawData {
            result.appendData(data)
        }
        return result
    }
    
    override func processContentData(data: NSData) {
        _rawData = data.subdataWithRange(NSMakeRange(0, Int(_initContentLength)))
    }
    
    func setRawData(data: NSData) {
        _rawData = data
    }
}

// Params meta
class ParamsMeta: FCGIMeta {
    // This stored property is an implicitly unwrapped optional so that we can
    // call super.init early on in the init process to retrieve the content length
    private var _params: FCGIRequestParams?
    var params: FCGIRequestParams? { return _params }    // read-only accessor
    
    override var type: FCGIMetaType { return .Params }
    
    override func processContentData(data: NSData) {
        var paramData: [String: String] = [:]
        
        //Remove Padding
        let unpaddedData = data.subdataWithRange(NSMakeRange(0, Int(contentLength))).mutableCopy() as NSMutableData
        while unpaddedData.length > 0 {
            var pos0 = 0
            var pos1 = 0
            var pos4 = 0
            
            var keyLengthB3 = 0
            var keyLengthB2 = 0
            var keyLengthB1 = 0
            var keyLengthB0 = 0
            
            var valueLengthB3 = 0
            var valueLengthB2 = 0
            var valueLengthB1 = 0
            var valueLengthB0 = 0
            
            var keyLength = 0
            var valueLength = 0
            
            unpaddedData.getBytes(&pos0, range: NSMakeRange(0, 1))
            unpaddedData.getBytes(&pos1, range: NSMakeRange(1, 1))
            unpaddedData.getBytes(&pos4, range: NSMakeRange(4, 1))
            
            if pos0 >> 7 == 0 {
                keyLength = pos0
                // NameValuePair11 or 14
                if pos1 >> 7 == 0 {
                    //NameValuePair11
                    valueLength = pos1
                    unpaddedData.replaceBytesInRange(NSMakeRange(0,2), withBytes: nil, length: 0)
                } else {
                    //NameValuePair14
                    unpaddedData.getBytes(&valueLengthB3, range: NSMakeRange(1, 1))
                    unpaddedData.getBytes(&valueLengthB2, range: NSMakeRange(2, 1))
                    unpaddedData.getBytes(&valueLengthB1, range: NSMakeRange(3, 1))
                    unpaddedData.getBytes(&valueLengthB0, range: NSMakeRange(4, 1))
                    
                    valueLength = ((valueLengthB3 & 0x7f) << 24) + (valueLengthB2 << 16) + (valueLengthB1 << 8) + valueLengthB0
                    unpaddedData.replaceBytesInRange(NSMakeRange(0,5), withBytes: nil, length: 0)
                }
            } else {
                // NameValuePair41 or 44
                unpaddedData.getBytes(&keyLengthB3, range: NSMakeRange(0, 1))
                unpaddedData.getBytes(&keyLengthB2, range: NSMakeRange(1, 1))
                unpaddedData.getBytes(&keyLengthB1, range: NSMakeRange(2, 1))
                unpaddedData.getBytes(&keyLengthB0, range: NSMakeRange(3, 1))
                keyLength = ((keyLengthB3 & 0x7f) << 24) + (keyLengthB2 << 16) + (keyLengthB1 << 8) + keyLengthB0
                
                if (pos4 >> 7 == 0) {
                    //NameValuePair41
                    valueLength = pos4
                    unpaddedData.replaceBytesInRange(NSMakeRange(0,5), withBytes: nil, length: 0)
                } else {
                    //NameValuePair44
                    unpaddedData.getBytes(&valueLengthB3, range: NSMakeRange(4, 1))
                    unpaddedData.getBytes(&valueLengthB2, range: NSMakeRange(5, 1))
                    unpaddedData.getBytes(&valueLengthB1, range: NSMakeRange(6, 1))
                    unpaddedData.getBytes(&valueLengthB0, range: NSMakeRange(7, 1))
                    valueLength = ((valueLengthB3 & 0x7f) << 24) + (valueLengthB2 << 16) + (valueLengthB1 << 8) + valueLengthB0
                    unpaddedData.replaceBytesInRange(NSMakeRange(0,8), withBytes: nil, length: 0)
                    
                }
            }
            
            let key = NSString(data: unpaddedData.subdataWithRange(NSMakeRange(0,keyLength)), encoding: NSUTF8StringEncoding)
            unpaddedData.replaceBytesInRange(NSMakeRange(0,keyLength), withBytes: nil, length: 0)
            
            let value = NSString(data: unpaddedData.subdataWithRange(NSMakeRange(0,valueLength)), encoding: NSUTF8StringEncoding)
            unpaddedData.replaceBytesInRange(NSMakeRange(0,valueLength), withBytes: nil, length: 0)
            
            if key != nil && value != nil {
                paramData[key!] = value!
            } else {
                fatalError("Unable to decode key or value from content")  // non-decodable value
            }
        }
        
        if paramData.count > 0 {
            _params = paramData
        } else {
            _params = nil
        }
    }
}


// MARK: Helper functions

func readUInt16FromBigEndianData(data: NSData, atIndex index: Int) -> UInt16 {
    var bigUInt16: UInt16 = 0
    data.getBytes(&bigUInt16, range: NSMakeRange(index, 2))
    return CFSwapInt16BigToHost(bigUInt16)
}

func createMetaFromHeaderData(data: NSData) -> FCGIMeta? {
    // Check the length of the data
    if data.length == 8 {
        // Parse the version number
        var rawVersion: FCGIVersion.RawValue = 0
        data.getBytes(&rawVersion, range: NSMakeRange(0, 1))
        
        if let version = FCGIVersion(rawValue: rawVersion) {
            // Check the version
            switch version {
            case .Version1:
                // Parse the request type
                var rawType: FCGIMetaType.RawValue = 0
                data.getBytes(&rawType, range: NSMakeRange(1, 1))
                
                if let type = FCGIMetaType(rawValue: rawType) {
                    // Parse the request ID
                    let requestID = readUInt16FromBigEndianData(data, atIndex: 2)
                    
                    // Parse the content length
                    let contentLength = readUInt16FromBigEndianData(data, atIndex: 4)
                    
                    // Parse the padding length
                    var paddingLength: FCGIPaddingLength = 0
                    data.getBytes(&paddingLength, range: NSMakeRange(6, 1))
                    
                    switch type {
                    case .BeginRequest:
                        return BeginRequestMeta(version: version, requestID: requestID, contentLength: contentLength, paddingLength: paddingLength)
                    case .Params:
                        return ParamsMeta(version: version, requestID: requestID, contentLength: contentLength, paddingLength: paddingLength)
                    case .Stdin:
                        return ByteStreamMeta(version: version, requestID: requestID, contentLength: contentLength, paddingLength: paddingLength)
                    default:
                        return nil
                    }
                }
            }
        }
    }
    
    return nil
}
