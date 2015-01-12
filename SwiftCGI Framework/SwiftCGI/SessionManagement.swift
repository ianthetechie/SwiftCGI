//
//  SessionManagement.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 1/8/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

public typealias SessionID = String
public typealias SessionData = [String: String]


// MARK: Protocol that session managers must conform to

public protocol SessionManager {
    func getDataForSessionID(sessionID: SessionID) -> SessionData?
    func setData(data: SessionData, forSessionID sessionID: SessionID)
    class func sharedInstance() -> SessionManager
}


public class RequestSessionManager<T: SessionManager> {
    let sessionID: SessionID!   // Implicitly unwrapped to prevent the return nil compiler error
    let sessionManager: SessionManager
    
    public init?(request: FCGIRequest) {
        self.sessionManager = T.sharedInstance()
        
        // TODO: this should be replaced with a property
        if let id = request.cookies?["sessionid"] {   // Extract the session ID
            sessionID = id
        } else {
            return nil
        }
    }
    
    public func getData() -> SessionData? {
        return sessionManager.getDataForSessionID(sessionID)
    }
    
    public func setData(data: SessionData) {
        sessionManager.setData(data, forSessionID: sessionID)
    }
}

// MARK: Can't get much more basic thatn this; session data is sent to /dev/null

public class NilSessionManager: SessionManager {
    public func getDataForSessionID(sessionID: SessionID) -> SessionData? {
        return nil
    }
    
    public func setData(data: SessionData, forSessionID sessionID: SessionID) {
        // Do nothing
    }
    
    public class func sharedInstance() -> SessionManager {
        struct Static {
            static let instance = NilSessionManager()
        }
        return Static.instance
    }
}


// MARK: Basic, transient in-memory session support; great for quick testing

public class TransientMemorySessionManager: SessionManager {
    private var sessionData: [String: SessionData] = [:]
    
    public func getDataForSessionID(sessionID: SessionID) -> SessionData? {
        return sessionData[sessionID]
    }
    
    public func setData(data: SessionData, forSessionID sessionID: SessionID) {
        sessionData[sessionID] = data
    }
    
    public class func sharedInstance() -> SessionManager {
        struct Static {
            static let instance = TransientMemorySessionManager()
        }
        return Static.instance
    }
}