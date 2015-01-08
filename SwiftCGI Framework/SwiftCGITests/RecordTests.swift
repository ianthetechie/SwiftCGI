//
//  RecordTests.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/8/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
import XCTest

class RecordTests: XCTestCase {
    // TODO: BeginRequestRecord
    
    func testEndRequestRecord() {
        let record = EndRequestRecord(version: .Version1, requestID: 1, paddingLength: 0, protocolStatus: .RequestComplete, applicationStatus: 0)
        XCTAssertEqual(record.type, FCGIRecordType.EndRequest, "Incorrect end request record type")
        
        let fcgiData = record.fcgiPacketData
        XCTAssertEqual(fcgiData.length, 16, "Incorrect packet data length")
        
        // Get the data as raw bytes for ease of verification
        var bytes = [UInt8](count: 16, repeatedValue: 0)
        fcgiData.getBytes(&bytes, length: 16)
        
        
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
        
        
        // Verify the remaining block of data
        XCTAssertEqual(bytes[8], UInt8(0), "Incorrect application status byte 1")
        XCTAssertEqual(bytes[9], UInt8(0), "Incorrect application status byte 2")
        XCTAssertEqual(bytes[10], UInt8(0), "Incorrect application status byte 3")
        XCTAssertEqual(bytes[11], UInt8(0), "Incorrect application status byte 4")
        
        XCTAssertEqual(bytes[12], record.protocolStatus.rawValue, "Incorrect protocol status")
        XCTAssertEqual(bytes[13], UInt8(0), "Incorrect reserved byte")
        XCTAssertEqual(bytes[14], UInt8(0), "Incorrect reserved byte")
        XCTAssertEqual(bytes[15], UInt8(0), "Incorrect reserved byte")
    }
    
    // TODO: ByteStreamRecord
    
    // TODO: ParamsRecord
    
    // TODO: createRecordFromHeaderData
}
