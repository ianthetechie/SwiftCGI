//
//  AppDelegate.swift
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

import Cocoa
import SwiftCGI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var server: FCGIServer!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        let requestHandler: FCGIRequestHandler = { request in
            var extraGreeting = ""
            if let sessionManager = request.getSessionManager() as RequestSessionManager<TransientMemorySessionManager>? {
                var sessionData: SessionData = sessionManager.getData() ?? [:]
                
                if sessionData["visited"] == "true" {
                    extraGreeting = " again"
                } else {
                    sessionData["visited"] = "true"
                }
                
                sessionManager.setData(sessionData)
            }
            
            return HTTPResponse(status: .OK, contentType: .TextPlain, body: "안녕하세요\(extraGreeting), Swifter! The time is now \(NSDate())")
        }
        
        server = FCGIServer(port: 9000, requestHandler: requestHandler)
        
        var err: NSError?
        server.startWithError(&err)
        
        if let error = err {
            println("Failed to start SwiftCGI server")
            println(err)
            exit(1)
        } else {
            println("Started SwiftCGI server on port \(server.port)")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

