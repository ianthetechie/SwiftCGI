//
//  SessionManagement.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/8/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

public typealias SessionData = [String: String]


// MARK: Protocol that session managers must conform to

public protocol SessionManager {
    func getDataForSessionID(sessionID: String) -> SessionData?
    func setData(data: SessionData, forSessionID sessionID: String)
}


// MARK: Can't get much more basic thatn this; session data is sent to /dev/null

public class NilSessionManager: SessionManager {
    public func getDataForSessionID(sessionID: String) -> SessionData? {
        return nil
    }
    
    public func setData(data: SessionData, forSessionID sessionID: String) {
        // Do nothing
    }
}


// MARK: Basic, transient in-memory session support; great for quick testing

public class TransientMemorySessionManager: SessionManager {
    private var sessionData: [String: SessionData] = [:]
    
    public func getDataForSessionID(sessionID: String) -> SessionData? {
        return sessionData[sessionID]
    }
    
    public func setData(data: SessionData, forSessionID sessionID: String) {
        sessionData[sessionID] = data
    }
}
