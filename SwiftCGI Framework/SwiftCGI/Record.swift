//
//  Record.swift
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


// MARK: Record classes

// Base struct (should never be directly instantiated)
class FCGIRecord {
    let version: FCGIVersion
    let requestID: FCGIRequestID
    
    // A public getter exposes the private constant storage because certain types
    // of record subclasses are used for incoming data (in which the content length
    // is known at instantiation), and others compute content length before
    // sending a packet.
    //
    // NOTE: The total data length = contentLenth + paddingLength. Padding
    // is extra data that is ignored.
    let _initContentLength: FCGIContentLength
    var contentLength: FCGIContentLength { return _initContentLength }
    
    let paddingLength: FCGIPaddingLength
    
    var type: FCGIRecordType { fatalError("Not Implemented") }
    
    var fcgiPacketData: NSData {
        var bytes = [UInt8](count: 8, repeatedValue: 0)
        bytes[0] = version.rawValue
        bytes[1] = UInt8(type.rawValue)
        
        let (msb, lsb) = requestID.decomposeBigEndian()
        bytes[2] = msb
        bytes[3] = lsb
        
        let bigEndianContentLength = CFSwapInt16HostToBig(contentLength)
        bytes[4] = UInt8(bigEndianContentLength & 0xFF) // MSB
        bytes[5] = UInt8(bigEndianContentLength >> 8)   // LSB
        
        bytes[6] = paddingLength
        
        return NSData(bytes: &bytes, length: 8)
    }
    
    init(version: FCGIVersion, requestID: FCGIRequestID, contentLength: FCGIContentLength, paddingLength: FCGIPaddingLength) {
        self.version = version
        self.requestID = requestID
        self._initContentLength = contentLength
        self.paddingLength = paddingLength
    }
    
    // TODO: Not sure if I like this approach of self-modifying objects...
    func processContentData(data: NSData) {
        fatalError("Not Implemented")
    }
}

// Begin request record
class BeginRequestRecord: FCGIRecord {
    var role: FCGIRequestRole?
    var flags: FCGIRequestFlags?
    
    override var type: FCGIRecordType { return .BeginRequest }
    
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

// End request record
class EndRequestRecord: FCGIRecord {
    let applicationStatus: FCGIApplicationStatus
    let protocolStatus: FCGIProtocolStatus
    
    override var type: FCGIRecordType { return .EndRequest }
    override var contentLength: FCGIContentLength { return 8 }  // Fixed value for this type
    
    init(version: FCGIVersion, requestID: FCGIRequestID, paddingLength: FCGIPaddingLength, protocolStatus: FCGIProtocolStatus, applicationStatus: FCGIApplicationStatus) {
        self.applicationStatus = applicationStatus
        self.protocolStatus = protocolStatus
        
        super.init(version: version, requestID: requestID, contentLength: 0, paddingLength: paddingLength)
    }
    
    override var fcgiPacketData: NSData {
        let result = super.fcgiPacketData.mutableCopy() as! NSMutableData
        
        var extraBytes = [UInt8](count: 8, repeatedValue: 0)
        
        let (msb, b1, b2, lsb) = applicationStatus.decomposeBigEndian()
        extraBytes[0] = msb
        extraBytes[1] = b1
        extraBytes[2] = b2
        extraBytes[3] = lsb
        
        extraBytes[4] = protocolStatus.rawValue
        
        result.appendData(NSData(bytes: &extraBytes, length: 8))
        
        return result
    }
}

// Data record
class ByteStreamRecord: FCGIRecord {
    private var _rawData: NSData?
    var rawData: NSData? { return _rawData }
    
    override var contentLength: FCGIContentLength { return FCGIContentLength(_rawData?.length ?? 0) }
    
    var _type: FCGIRecordType = .Stdin
    override var type: FCGIRecordType {
        get { return _type }
        set {
            switch newValue {
            case .Stdin, .Stdout, .Stderr:
                _type = newValue
            default:
                fatalError("ByteStreamRecord.type can only be .Stdin .Stdout or .Stderr")
            }
        }
    }
    
    override var fcgiPacketData: NSData {
        let result = super.fcgiPacketData.mutableCopy() as! NSMutableData
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

// Params record
class ParamsRecord: FCGIRecord {
    // This stored property is an implicitly unwrapped optional so that we can
    // call super.init early on in the init process to retrieve the content length
    private var _params: RequestParams?
    var params: RequestParams? { return _params }    // read-only accessor
    
    override var type: FCGIRecordType { return .Params }
    
    override func processContentData(data: NSData) {
        var paramData: [String: String] = [:]
        
        //Remove Padding
        let unpaddedData = data.subdataWithRange(NSMakeRange(0, Int(contentLength))).mutableCopy() as! NSMutableData
        while unpaddedData.length > 0 {
            var pos0 = 0, pos1 = 0, pos4 = 0
            
            var keyLengthB3 = 0, keyLengthB2 = 0, keyLengthB1 = 0, keyLengthB0 = 0
            
            var valueLengthB3 = 0, valueLengthB2 = 0, valueLengthB1 = 0, valueLengthB0 = 0
            
            var keyLength = 0, valueLength = 0
            
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
            
            if let key = key as? String, value = value as? String {
                paramData[key] = value
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

func createRecordFromHeaderData(data: NSData) -> FCGIRecord? {
    // Check the length of the data
    if data.length == Int(FCGIRecordHeaderLength) {
        // Parse the version number
        var rawVersion: FCGIVersion.RawValue = 0
        data.getBytes(&rawVersion, range: NSMakeRange(0, 1))
        
        if let version = FCGIVersion(rawValue: rawVersion) {
            // Check the version
            switch version {
            case .Version1:
                // Parse the request type
                var rawType: FCGIRecordType.RawValue = 0
                data.getBytes(&rawType, range: NSMakeRange(1, 1))
                
                if let type = FCGIRecordType(rawValue: rawType) {
                    // Parse the request ID
                    let requestID = readUInt16FromBigEndianData(data, atIndex: 2)
                    
                    // Parse the content length
                    let contentLength = readUInt16FromBigEndianData(data, atIndex: 4)
                    
                    // Parse the padding length
                    var paddingLength: FCGIPaddingLength = 0
                    data.getBytes(&paddingLength, range: NSMakeRange(6, 1))
                    
                    switch type {
                    case .BeginRequest:
                        return BeginRequestRecord(version: version, requestID: requestID, contentLength: contentLength, paddingLength: paddingLength)
                    case .Params:
                        return ParamsRecord(version: version, requestID: requestID, contentLength: contentLength, paddingLength: paddingLength)
                    case .Stdin:
                        return ByteStreamRecord(version: version, requestID: requestID, contentLength: contentLength, paddingLength: paddingLength)
                    default:
                        return nil
                    }
                }
            }
        }
    }
    
    return nil
}
