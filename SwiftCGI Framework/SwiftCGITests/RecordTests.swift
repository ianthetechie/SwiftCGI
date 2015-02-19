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
    
    func testParamsRecord() {
        // NOTE: The following test data was derived from an NSData dump gathered using the lldb console.
        // The NSData output was something like 0f0c5343 52495054 5f46494c ...
        // The following Python code was used to convert this into base64, for
        // easy ingestion as NSData for testing purposes here. Also, make sure
        // you check the padding and content length (technically only the content
        // length matters, but yeah...).
        //
        // import struct
        // import base64
        //
        // data_string = '0f0c5343 52495054 5f46494c ...' // replace with actual data
        // words = data_string.split()
        // data_string = struct.pack('!%s' % ('I' * len(words)), *[int(x, 16) for x in words])  // pack the parsed chunks into a string
        // print base64.b64decode(data_string)
        let data = NSData(base64EncodedString: "DwxTQ1JJUFRfRklMRU5BTUUvc2NyaXB0cy9jZ2kMAFFVRVJZX1NUUklORw4DUkVRVUVTVF9NRVRIT0RHRVQMAENPTlRFTlRfVFlQRQ4AQ09OVEVOVF9MRU5HVEgLBFNDUklQVF9OQU1FL2NnaQsEUkVRVUVTVF9VUkkvY2dpDARET0NVTUVOVF9VUkkvY2dpDSJET0NVTUVOVF9ST09UL3Vzci9sb2NhbC9DZWxsYXIvbmdpbngvMS42LjIvaHRtbA8IU0VSVkVSX1BST1RPQ09MSFRUUC8xLjERB0dBVEVXQVlfSU5URVJGQUNFQ0dJLzEuMQ8LU0VSVkVSX1NPRlRXQVJFbmdpbngvMS42LjILCVJFTU9URV9BRERSMTI3LjAuMC4xCwVSRU1PVEVfUE9SVDU3MTk4CwlTRVJWRVJfQUREUjEyNy4wLjAuMQsEU0VSVkVSX1BPUlQ4MDgwCwlTRVJWRVJfTkFNRWxvY2FsaG9zdA8DUkVESVJFQ1RfU1RBVFVTMjAwCQ5IVFRQX0hPU1Rsb2NhbGhvc3Q6ODA4MAsISFRUUF9QUkFHTUFuby1jYWNoZQsuSFRUUF9DT09LSUVzZXNzaW9uaWQ9ODQwNUY4NUUtOTQ5Ni00NUEwLUE3MjQtREI5RDkzMDEwN0Q0DwpIVFRQX0NPTk5FQ1RJT05rZWVwLWFsaXZlCz9IVFRQX0FDQ0VQVHRleHQvaHRtbCxhcHBsaWNhdGlvbi94aHRtbCt4bWwsYXBwbGljYXRpb24veG1sO3E9MC45LCovKjtxPTAuOA92SFRUUF9VU0VSX0FHRU5UTW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTBfMikgQXBwbGVXZWJLaXQvNjAwLjMuMTggKEtIVE1MLCBsaWtlIEdlY2tvKSBWZXJzaW9uLzguMC4zIFNhZmFyaS82MDAuMy4xOBQFSFRUUF9BQ0NFUFRfTEFOR1VBR0Vlbi11cxQNSFRUUF9BQ0NFUFRfRU5DT0RJTkdnemlwLCBkZWZsYXRlEglIVFRQX0NBQ0hFX0NPTlRST0xtYXgtYWdlPTAAAAAAAA==", options: .allZeros)!
        let paddingLength = 5
        let record = ParamsRecord(version: .Version1, requestID: 1, contentLength: 832 - paddingLength, paddingLength: FCGIPaddingLength(paddingLength))
        record.processContentData(data)
        
        let expectedResult = ["SERVER_ADDR": "127.0.0.1",
            "HTTP_USER_AGENT": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/600.3.18 (KHTML, like Gecko) Version/8.0.3 Safari/600.3.18",
            "HTTP_CACHE_CONTROL": "max-age=0",
            "REMOTE_ADDR": "127.0.0.1",
            "HTTP_ACCEPT_LANGUAGE": "en-us",
            "DOCUMENT_URI": "/cgi",
            "GATEWAY_INTERFACE": "CGI/1.1",
            "HTTP_COOKIE": "sessionid=8405F85E-9496-45A0-A724-DB9D930107D4",
            "HTTP_ACCEPT": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "SCRIPT_NAME": "/cgi",
            "HTTP_HOST": "localhost:8080",
            "REQUEST_METHOD": "GET",
            "SERVER_PROTOCOL": "HTTP/1.1",
            "SERVER_NAME": "localhost",
            "HTTP_PRAGMA": "no-cache",
            "SCRIPT_FILENAME": "/scripts/cgi",
            "CONTENT_TYPE": "",
            "CONTENT_LENGTH": "",
            "REQUEST_URI": "/cgi",
            "DOCUMENT_ROOT": "/usr/local/Cellar/nginx/1.6.2/html",
            "SERVER_SOFTWARE": "nginx/1.6.2",
            "SERVER_PORT": "8080",
            "HTTP_CONNECTION": "keep-alive",
            "REMOTE_PORT": "57198",
            "HTTP_ACCEPT_ENCODING": "gzip, deflate",
            "QUERY_STRING": "",
            "REDIRECT_STATUS": "200"]
        XCTAssert(record.params != nil && expectedResult == record.params!, "Incorrect params record parsing result")
    }
    
    // TODO: createRecordFromHeaderData
}
