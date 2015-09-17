//
//  UIntExtensions.swift
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

// Design note: yes, this is very meta, aliasing an alias, but it is readable.
typealias MSB = UInt8
typealias LSB = UInt8

extension UInt16 {
    func decomposeBigEndian() -> (MSB, LSB) {
        let bigEndianValue = CFSwapInt16HostToBig(self)
        let msb = UInt8(bigEndianValue & 0xFF)
        let lsb = UInt8(bigEndianValue >> 8)
        
        return (msb, lsb)
    }
    
    func decomposeLittleEndian() -> (LSB, MSB) {
        let littleEndianValue = CFSwapInt16HostToLittle(self)
        let lsb = UInt8(littleEndianValue & 0xFF)
        let msb = UInt8(littleEndianValue >> 8)
        
        return (lsb, msb)
    }
}

// Does the same decomposition as the above, but for 32-bit UInts
extension UInt32 {
    func decomposeBigEndian() -> (MSB, UInt8, UInt8, LSB) {
        let bigEndianValue = CFSwapInt32HostToBig(self)
        let msb = UInt8(bigEndianValue & 0xFF)
        let b1 = UInt8((bigEndianValue >> 8) & 0xFF)
        let b2 = UInt8((bigEndianValue >> 16) & 0xFF)
        let lsb = UInt8((bigEndianValue >> 24) & 0xFF)
        
        return (msb, b1, b2, lsb)
    }
    
    func decomposeLittleEndian() -> (LSB, UInt8, UInt8, MSB) {
        let littleEndianValue = CFSwapInt32HostToLittle(self)
        let lsb = UInt8(littleEndianValue & 0xFF)
        let b1 = UInt8((littleEndianValue >> 8) & 0xFF)
        let b2 = UInt8((littleEndianValue >> 16) & 0xFF)
        let msb = UInt8((littleEndianValue >> 24) & 0xFF)
        
        return (lsb, b1, b2, msb)
    }
}