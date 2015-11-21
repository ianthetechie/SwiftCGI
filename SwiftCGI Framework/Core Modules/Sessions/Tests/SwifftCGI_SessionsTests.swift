//
//  SwifftCGI_SessionsTests.swift
//  SwifftCGI SessionsTests
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

class SwifftCGI_SessionsTests: XCTestCase {
    let randomSessionID = "LSkjhafdfsiFNDSF97(*^FDfs5FDS&fSusGDFfsdfgjvbcm,"
    
    func testNilSessionManager() {
        let manager = NilSessionManager.instance
        
        // Verify that we don't have a session yet
        XCTAssert(manager.getDataForSessionID(randomSessionID) == nil, "Initial session data should be nil")
        
        // Verify that we can persist a key
        let sessionData: SessionData = ["foo": "bar"]
        manager.setData(sessionData, forSessionID: randomSessionID)
        
        let persistedSessionData = manager.getDataForSessionID(randomSessionID)
        XCTAssert(persistedSessionData == nil, "Session data should not stored by NilSessionManager")
    }
    
    func testTransientMemorySessionManager() {
        let manager = TransientMemorySessionManager.instance
        
        // Verify that we don't have a session yet
        XCTAssert(manager.getDataForSessionID(randomSessionID) == nil, "Initial session data should be nil")
        
        // Verify that we can persist a key
        let sessionData: SessionData = ["foo": "bar"]
        manager.setData(sessionData, forSessionID: randomSessionID)
        
        let persistedSessionData = manager.getDataForSessionID(randomSessionID)
        XCTAssert(persistedSessionData != nil, "Session data was not stored")
        XCTAssert(persistedSessionData! == sessionData, "Stored session data does not match")
    }

    // TODO: Figure out how to test this... too many private types
    func testRequestSessionManager() {
        var record = BeginRequestRecord(version: .Version1, requestID: 1, contentLength: 8, paddingLength: 0)
        record.role = FCGIRequestRole.Responder
        record.flags = FCGIRequestFlags.allZeros
        
        var request = FCGIRequest(record: record)
        
        let nilManager = RequestSessionManager<TransientMemorySessionManager>(request: request)
        XCTAssert(nilManager == nil, "Initializer should fail when there is no sessionid parameter")
        
        request.generateSessionID()
        
        let manager = RequestSessionManager<TransientMemorySessionManager>(request: request)
        XCTAssert(manager != nil, "Initializer should no longer fail")
        
        // Verify that we don't have a session yet
        XCTAssert(manager!.getData() == nil, "Initial session data should be nil")
        
        // Verify that we can persist a key
        let sessionData: SessionData = ["foo": "bar"]
        manager!.setData(sessionData)
        
        let persistedSessionData = manager!.getData()
        XCTAssert(persistedSessionData != nil, "Session data was not stored")
        XCTAssert(persistedSessionData! == sessionData, "Stored session data does not match")
    }
}
