//
//  PrimitiveTests.swift
//  SwiftCGITests
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

import Cocoa
import XCTest

class PrimitiveTests: XCTestCase {
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
    
    func testUInt16FromBigEndianData() {
        let originalValue = UInt16(0xF00F)
        let (msb, lsb) = originalValue.decomposeBigEndian()
        
        var bytes = [UInt8](count:8, repeatedValue: 0)
        bytes[0] = msb
        bytes[1] = lsb
        
        // Throw in the value again later in the block to make sure the index
        // argument is working properly
        bytes[3] = msb
        bytes[4] = lsb
        
        let bigEndianData = NSData(bytes: &bytes, length: 8)
        let parsedValue = readUInt16FromBigEndianData(bigEndianData, atIndex: 0)
        XCTAssertEqual(originalValue, parsedValue, "Incorrect result from readUInt16FromBigEndianData")
        
        let parsedValueWithOffset = readUInt16FromBigEndianData(bigEndianData, atIndex: 3)
        XCTAssertEqual(originalValue, parsedValueWithOffset, "Incorrect result from readUInt16FromBigEndianData")
        
        let parsedValueWithInvalidOffset = readUInt16FromBigEndianData(bigEndianData, atIndex: 2)
        XCTAssert(originalValue != parsedValueWithInvalidOffset, "Incorrect result from readUInt16FromBigEndianData")
    }
}
