//
//  HTTPParser.swift
//  SwiftCGI
//
//  Created by Todd Bluhm on 9/26/15.
//  Copyright © 2015 Ian Wagner. All rights reserved.
//

import CHTTPParser.Parser
import CHTTPParser.Accessors

struct HttpParserRequest {
    var method: String?
    var body: String?
    var url: String?
    var headers: [String:String]?
    var lastHeaderWasValue = true
    var isMessageComplete = false
    var headerName: String?
    var completeMethod: (() -> ())?
}

func ==(lhs: HttpParser, rhs: HttpParser) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

class HttpParser: Hashable {
    var parser = http_parser()
    var data = HttpParserRequest()
    var settings: http_parser_settings
    var hashValue: Int {
        get {
            return "\(parser)".hashValue
        }
    }
    var delegate: HTTPBackend?
    
    init() {
        settings = http_parser_settings(
            on_message_begin: nil,
            on_url: onReceivedUrl,
            on_status: nil,
            on_header_field: onReceivedHeaderName,
            on_header_value: onReceivedHeaderValue,
            on_headers_complete: nil,
            on_body: onReceivedBody,
            on_message_complete: onMessageComplete,
            on_chunk_header: nil,
            on_chunk_complete: nil
        )
        
        data.completeMethod = requestComplete
        
        withUnsafeMutablePointer(&data) { (data: UnsafeMutablePointer<HttpParserRequest>) -> Void in
            parser.data = UnsafeMutablePointer<Void>(data)
            http_parser_init(&parser, HTTP_REQUEST)
        }
    }
    
    func requestComplete () {
        delegate?.finishedRequestConstruction(self)
    }
    
    func parseData(data: NSData) {
        http_parser_execute(&parser, &settings, UnsafePointer<Int8>(data.bytes), data.length)
    }
}

func onMessageComplete(parser: UnsafeMutablePointer<http_parser>) -> Int32 {
    let dataPtr = UnsafeMutablePointer<HttpParserRequest>(parser.memory.data)
    dataPtr.memory.isMessageComplete = true
    dataPtr.memory.method = String.fromCString(http_parser_get_method(parser))
    dataPtr.memory.completeMethod?()
    return 0
}

func onReceivedHeaderName(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
    let dataPtr = UnsafeMutablePointer<HttpParserRequest>(parser.memory.data)
    
    if dataPtr.memory.headerName == nil {
        dataPtr.memory.headerName = ""
    }
    
    // Lets convert all this const char* stuff to native swift strings
    if let headerName = dataPtr.memory.headerName,
        let newPiece = String.fromCString(UnsafePointer<CChar>(data)) {
            
            // Use length to get the proper substring from the data
            let start = newPiece.startIndex
            let end = start.advancedBy(length-1)
            
            // If the last piece of data recieved was a head value then
            // this must be the start of a new header
            if dataPtr.memory.lastHeaderWasValue {
                dataPtr.memory.headerName = newPiece[start...end]
                // otherwise lets append on to the previous header value
            } else {
                dataPtr.memory.headerName = headerName + newPiece[start...end]
            }
            
            dataPtr.memory.lastHeaderWasValue = false
    }
    
    return 0
}

func onReceivedHeaderValue(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
    let dataPtr = UnsafeMutablePointer<HttpParserRequest>(parser.memory.data)
    
    if dataPtr.memory.headers == nil {
        dataPtr.memory.headers = [:]
    }
    
    // Lets convert all this const char* stuff to native swift strings
    if let headerName = dataPtr.memory.headerName,
        let newPiece = String.fromCString(UnsafePointer<CChar>(data)) {
            
            // Use length to get the proper substring from the data
            let start = newPiece.startIndex
            let end = start.advancedBy(length-1)
            
            // If the last piece of data recieved was not a head value then
            // we need to add this data as the start header value
            if !dataPtr.memory.lastHeaderWasValue {
                dataPtr.memory.headers![headerName] = newPiece[start...end]
                // otherwise lets append on to the previous header value
            } else {
                if let partialValue = dataPtr.memory.headers![headerName] {
                    dataPtr.memory.headers![headerName] = partialValue + newPiece[start...end]
                }
            }
            
            dataPtr.memory.lastHeaderWasValue = true
    }
    
    
    return 0
}

func onReceivedUrl(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
    let dataPtr = UnsafeMutablePointer<HttpParserRequest>(parser.memory.data)
    
    if dataPtr.memory.url == nil {
        dataPtr.memory.url = ""
    }
    
    // Lets convert all this const char* stuff to native swift strings
    if let url = dataPtr.memory.url,
        let newPiece = String.fromCString(UnsafePointer<CChar>(data)) {
            // Use length to get the proper substring from the data
            let start = newPiece.startIndex
            let end = start.advancedBy(length-1)
            
            dataPtr.memory.url = url + newPiece[start...end]
    }
    
    return 0
}

func onReceivedBody(parser: UnsafeMutablePointer<http_parser>, data: UnsafePointer<Int8>, length: Int) -> Int32 {
    let dataPtr = UnsafeMutablePointer<HttpParserRequest>(parser.memory.data)
    
    if dataPtr.memory.body == nil {
        dataPtr.memory.body = ""
    }
    
    // Lets convert all this const char* stuff to native swift strings
    if let body = dataPtr.memory.body,
        let newPiece = String.fromCString(UnsafePointer<CChar>(data)) {
            let start = newPiece.startIndex
            let end = start.advancedBy(length-1)
            
            dataPtr.memory.body = body + newPiece[start...end]
    }
    
    return 0
}
