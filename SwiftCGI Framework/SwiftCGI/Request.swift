//
//  Request.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import Foundation

public enum RequestCompletionStatus {
    case Complete
}

public protocol Request {
    var cookies: [String: String]? { get set }
    var params: RequestParams { get }   /// Used to store things like CGI environment variables
    var path: String { get }
    var streamData: NSMutableData? { get set }
    var socket: GCDAsyncSocket? { get set }
    
    // TODO: writeResponseData (or something similar)
    func finish(status: RequestCompletionStatus)
}