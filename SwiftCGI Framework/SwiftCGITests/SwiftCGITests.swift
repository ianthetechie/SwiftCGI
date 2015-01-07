//
//  SwiftCGITests.swift
//  SwiftCGITests
//
//  Created by Ian Wagner on 1/4/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Cocoa
import XCTest

class SwiftCGITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // MARK: Easy stuff first - bit twiddling!
    
    func testDecomposeBigEndian() {
        // Test the big endian byte decomposition methods
        let (msb, lsb) = UInt16(0xF00F).decomposeBigEndian()
        XCTAssertEqual(msb, UInt8(0xF0), "MSB should be 0xF0")
        XCTAssertEqual(lsb, UInt8(0x0F), "LSB should be 0x0F")
    }
    
    func testDecomposeLittleEndian() {
        // Test the little endian byte decomposition methods
        let (lsb, msb) = UInt16(0xF00F).decomposeLittleEndian()
        XCTAssertEqual(lsb, UInt8(0x0F), "LSB should be 0x0F")
        XCTAssertEqual(msb, UInt8(0xF0), "MSB should be 0xF0")
    }
    
    
    // MARK: Meta tests
    
    // TODO: BeginRequestMeta
    
    func testEndRequestMeta() {
        let meta = EndRequestMeta(version: .Version1, requestID: 1, paddingLength: 0, protocolStatus: .RequestComplete, applicationStatus: 0)
        XCTAssertEqual(meta.type, FCGIMetaType.EndRequest, "Incorrect end request meta type")
        
        let fcgiData = meta.fcgiPacketData
        XCTAssertEqual(fcgiData.length, 16, "Incorrect packet data length")
        
        // Get the data as raw bytes for ease of verification
        var bytes = [UInt8](count: 16, repeatedValue: 0)
        fcgiData.getBytes(&bytes, length: 16)
        
        
        // Verify the header bytes
        XCTAssertEqual(bytes[0], FCGIVersion.Version1.rawValue, "Incorrect FCGI version")
        XCTAssertEqual(bytes[1], meta.type.rawValue, "Incorrect type")
        
        let (requestIDMSB, requestIDLSB) = meta.requestID.decomposeBigEndian()
        XCTAssertEqual(bytes[2], requestIDMSB, "Incorrect request ID MSB")
        XCTAssertEqual(bytes[3], requestIDLSB, "Incorrect request ID LSB")
        
        let (contentLengthMSB, contentLengthLSB) = meta.contentLength.decomposeBigEndian()
        XCTAssertEqual(bytes[4], contentLengthMSB, "Incorrect content length MSB")
        XCTAssertEqual(bytes[5], contentLengthLSB, "Incorrect content length LSB")
        
        XCTAssertEqual(bytes[6], meta.paddingLength, "Incorrect padding length")
        XCTAssertEqual(bytes[7], UInt8(0), "Incorrect reserved byte")
        
        
        // Verify the remaining block of data
        XCTAssertEqual(bytes[8], UInt8(0), "Incorrect application status byte 1")
        XCTAssertEqual(bytes[9], UInt8(0), "Incorrect application status byte 2")
        XCTAssertEqual(bytes[10], UInt8(0), "Incorrect application status byte 3")
        XCTAssertEqual(bytes[11], UInt8(0), "Incorrect application status byte 4")
        
        XCTAssertEqual(bytes[12], meta.protocolStatus.rawValue, "Incorrect protocol status")
        XCTAssertEqual(bytes[13], UInt8(0), "Incorrect reserved byte")
        XCTAssertEqual(bytes[14], UInt8(0), "Incorrect reserved byte")
        XCTAssertEqual(bytes[15], UInt8(0), "Incorrect reserved byte")
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
