//
//  SessionManagementTests.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/8/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import XCTest

class SessionManagementTests: XCTestCase {
    let randomSessionID = "LSkjhafdfsiFNDSF97(*^FDfs5FDS&fSusGDFfsdfgjvbcm,"
    
    func testNilSessionManager() {
        let manager = NilSessionManager()
        
        // Verify that we don't have a session yet
        XCTAssert(manager.getDataForSessionID(randomSessionID) == nil, "Initial session data should be nil")
        
        // Verify that we can persist a key
        let sessionData: SessionData = ["foo": "bar"]
        manager.setData(sessionData, forSessionID: randomSessionID)
        
        let persistedSessionData = manager.getDataForSessionID(randomSessionID)
        XCTAssert(persistedSessionData == nil, "Session data should not stored by NilSessionManager")
    }
    
    func testTransientMemorySessionManager() {
        let manager = TransientMemorySessionManager()
        
        // Verify that we don't have a session yet
        XCTAssert(manager.getDataForSessionID(randomSessionID) == nil, "Initial session data should be nil")
        
        // Verify that we can persist a key
        let sessionData: SessionData = ["foo": "bar"]
        manager.setData(sessionData, forSessionID: randomSessionID)
        
        let persistedSessionData = manager.getDataForSessionID(randomSessionID)
        XCTAssert(persistedSessionData != nil, "Session data was not stored")
        XCTAssert(persistedSessionData! == sessionData, "Stored session data does not match")
    }
    
    func testRequestSessionManager() {
        let record = BeginRequestRecord(version: .Version1, requestID: 1, contentLength: 8, paddingLength: 0)
        record.role = FCGIRequestRole.Responder
        record.flags = FCGIRequestFlags.allZeros
        
        let request = FCGIRequest(record: record)
        request._params = [:]
        
        let nilManager = RequestSessionManager<TransientMemorySessionManager>(request: request)
        XCTAssert(nilManager == nil, "Initializer should fail when there is no sessionid parameter")
        
        request._params["HTTP_COOKIE"] = "sessionid=foobar"
        
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
