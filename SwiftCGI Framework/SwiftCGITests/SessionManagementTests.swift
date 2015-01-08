//
//  SessionManagementTests.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/8/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation
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
}