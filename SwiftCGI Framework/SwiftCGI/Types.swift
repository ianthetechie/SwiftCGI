//
//  Types.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/4/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation


// MARK: Public types

public typealias FCGIRequestParams = [String: String]
public typealias FCGIRequestHandler = FCGIRequest -> Void

public typealias FCGIApplicationStatus = UInt32


public enum FCGIOutputStream: UInt8 {
    case Stdout = 6
    case Stderr = 7
}

public enum FCGIProtocolStatus: UInt8 {
    case RequestComplete = 0
    case FCGI_CANT_MPX_CONN = 1
    case Overloaded = 2
}


// MARK: Private types

typealias FCGIRequestId = UInt16
typealias FCGIContentLength = UInt16
typealias FCGIPaddingLength = UInt8
typealias FCGIShortNameLength = UInt8
typealias FCGILongNameLength = UInt32
typealias FCGIShortValueLength = UInt8
typealias FCGILongValueLength = UInt32


enum FCGIVersion: UInt8 {
    case Version1 = 1
}

enum FCGIRequestRole: UInt16 {
    case Responder = 1
    
    // Not implemented
    //case Authorizer = 2
    //case Filter = 3
}

enum FCGIMetaType: UInt8 {
    case BeginRequest = 1
    case AbortRequest = 2
    case EndRequest = 3
    case Params = 4
    case Stdin = 5
    case Stdout = 6
    case Stderr = 7
    case Data = 8
    case GetValues = 9
    case GetValuesResult = 10
}

struct FCGIRequestFlags : RawOptionSetType, BooleanType {
    typealias RawValue = UInt
    private var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    init(rawValue value: UInt) { self.value = value }
    init(nilLiteral: ()) { self.value = 0 }
    static var allZeros: FCGIRequestFlags { return self(0) }
    static func fromMask(raw: UInt) -> FCGIRequestFlags { return self(raw) }
    var rawValue: UInt { return self.value }
    var boolValue: Bool { return self.value != 0 }
    
    static var None: FCGIRequestFlags { return self(0) }
    static var KeepConnection: FCGIRequestFlags { return FCGIRequestFlags(1 << 0) }
}

enum FCGISocketTag: Int {
    case AwaitingHeaderTag = 0
    case AwaitingContentAndPaddingTag
}
