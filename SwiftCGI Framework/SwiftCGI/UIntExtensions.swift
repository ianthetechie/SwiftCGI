//
//  UIntExtensions.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/6/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

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
