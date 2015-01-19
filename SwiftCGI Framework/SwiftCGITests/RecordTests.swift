//
//  RecordTests.swift
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

import XCTest

class RecordTests: XCTestCase {
    func verifyBasicInfoAndHeaderForRecord(record: FCGIRecord) {
        let fcgiData = record.fcgiPacketData
        
        // Get the data as raw bytes for ease of verification
        var bytes = [UInt8](count: 8, repeatedValue: 0)
        fcgiData.getBytes(&bytes, length: 8)
        
        
        // Verify the header bytes
        XCTAssertEqual(bytes[0], FCGIVersion.Version1.rawValue, "Incorrect FCGI version")
        XCTAssertEqual(bytes[1], record.type.rawValue, "Incorrect type")
        
        let (requestIDMSB, requestIDLSB) = record.requestID.decomposeBigEndian()
        XCTAssertEqual(bytes[2], requestIDMSB, "Incorrect request ID MSB")
        XCTAssertEqual(bytes[3], requestIDLSB, "Incorrect request ID LSB")
        
        let (contentLengthMSB, contentLengthLSB) = record.contentLength.decomposeBigEndian()
        XCTAssertEqual(bytes[4], contentLengthMSB, "Incorrect content length MSB")
        XCTAssertEqual(bytes[5], contentLengthLSB, "Incorrect content length LSB")
        
        XCTAssertEqual(bytes[6], record.paddingLength, "Incorrect padding length")
        XCTAssertEqual(bytes[7], UInt8(0), "Incorrect reserved byte")
    }
    
    func testBeginRequestRecord() {
        let record = BeginRequestRecord(version: .Version1, requestID: 1, contentLength: 8, paddingLength: 0)
        verifyBasicInfoAndHeaderForRecord(record)
        XCTAssertEqual(record.type, FCGIRecordType.BeginRequest, "Incorrect record type")
        
        XCTAssertEqual(record.fcgiPacketData.length, 8, "Incorrect packet data length")
        
        // Verify that the processContentData function works correctly
        let role = FCGIRequestRole.Responder
        let (roleMSB, roleLSB) = role.rawValue.decomposeBigEndian()
        let flags = FCGIRequestFlags.KeepConnection
        
        var extraBytes = [UInt8](count: 8, repeatedValue: 0)
        extraBytes[0] = roleMSB
        extraBytes[1] = roleLSB
        extraBytes[2] = UInt8(flags.rawValue)   // Flag to keep the connection active
        
        let extraData = NSData(bytes: &extraBytes, length: 8)
        record.processContentData(extraData)
        
        XCTAssertEqual(record.role, role, "Incorrect role parsed from record data")
        XCTAssertEqual(record.flags, flags, "Incorrect flags parsed")
    }
    
    func testEndRequestRecord() {
        let record = EndRequestRecord(version: .Version1, requestID: 1, paddingLength: 0, protocolStatus: .RequestComplete, applicationStatus: 0)
        
        verifyBasicInfoAndHeaderForRecord(record)
        XCTAssertEqual(record.type, FCGIRecordType.EndRequest, "Incorrect record type")
        
        let fcgiData = record.fcgiPacketData
        XCTAssertEqual(fcgiData.length, 16, "Incorrect packet data length")
        
        // Get the data as raw bytes for ease of verification
        var bytes = [UInt8](count: 16, repeatedValue: 0)
        fcgiData.getBytes(&bytes, length: 16)
        
        // Verify the extra block of data after the header
        XCTAssertEqual(bytes[8], UInt8(0), "Incorrect application status byte 1")
        XCTAssertEqual(bytes[9], UInt8(0), "Incorrect application status byte 2")
        XCTAssertEqual(bytes[10], UInt8(0), "Incorrect application status byte 3")
        XCTAssertEqual(bytes[11], UInt8(0), "Incorrect application status byte 4")
        
        XCTAssertEqual(bytes[12], record.protocolStatus.rawValue, "Incorrect protocol status")
        XCTAssertEqual(bytes[13], UInt8(0), "Incorrect reserved byte")
        XCTAssertEqual(bytes[14], UInt8(0), "Incorrect reserved byte")
        XCTAssertEqual(bytes[15], UInt8(0), "Incorrect reserved byte")
    }
    
    func testByteStreamRecord() {
        let record = ByteStreamRecord(version: .Version1, requestID: 1, contentLength: 0, paddingLength: 0)
        
        verifyBasicInfoAndHeaderForRecord(record)
        XCTAssertEqual(record.type, FCGIRecordType.Stdin, "Incorrect record type")
        
        XCTAssertEqual(record.fcgiPacketData.length, 8, "Incorrect packet data length (before processContentData)")
        
        // Generate some random data
        let numBytes = 16
        var bytes = [UInt8](count: numBytes, repeatedValue: 0)
        for i in 0..<numBytes {
            bytes[i] = UInt8(rand() % 255)
        }
        
        // Load it into the record
        let byteData = NSData(bytes: &bytes, length: numBytes)
        record.processContentData(byteData)
        
        // This should still be 8, since we kindof initialized the packet with
        // contentLength of zero ;)
        XCTAssertEqual(record.fcgiPacketData.length, 8, "Incorrect packet data length (after processContentData)")
        
        // NOW we manually set the data
        record.setRawData(byteData)
        XCTAssertEqual(record.contentLength, UInt16(numBytes), "Incorrect content length (after setRawData)")
        XCTAssertEqual(record.fcgiPacketData.length, 8 + numBytes, "Incorrect packet data length (after setRawData)")
        
        let fcgiData = record.fcgiPacketData
        var fcgiBytes = [UInt8](count: numBytes, repeatedValue: 0)
        fcgiData.getBytes(&fcgiBytes, range: NSMakeRange(8, numBytes))
        
        // Verify that the data is correct
        for i in 0..<numBytes {
            XCTAssertEqual(bytes[i], fcgiBytes[i], "Incorrect byte encountered")
        }
    }
    
    // TODO: ParamsRecord
    
    // TODO: createRecordFromHeaderData
}
