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
import SwiftCGISessions

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // UI junk. Because Cocoa app...
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1) // workaround for a linker bug that prevents use of the proper constants
    
    var server: FCGIServer!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        // TODO: Clean up this kludge
        // NOTE: You should change the root path to match your server configuration
        let rootRouter = Router(path: "cgi", handleWildcardChildren: false, withHandler: rootHandler)
        
        let blogRouter = Router(path: "blog", handleWildcardChildren: true, withHandler: blogRootHandler)
        rootRouter.attachRouter(blogRouter)
        
        #if EMBED_SERVER
            server = FCGIServer(port: 9000, requestRouter: rootRouter, useEmbeddedHTTPServer: true)
        #else
            server = FCGIServer(port: 9000, requestRouter: rootRouter, useEmbeddedHTTPServer: false)
        #endif
        
        // Set up middleware
        server.registerMiddlewareHandler(sessionMiddlewareHandler)
        
        do {
            try server.start()
            print("Started SwiftCGI server on port \(server.port)")
        } catch {
            print("Failed to start SwiftCGI server")
            exit(1)
        }
        
        // Set ourselves up in the status bar (top of the screen)
        statusItem.title = "SwiftCGI"   // TODO: Use a logo
        
        let menu = NSMenu()
        menu.addItemWithTitle("Kill Server", action: Selector("killServer:"), keyEquivalent: "")
        
        statusItem.menu = menu
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func killServer(sender: AnyObject!) {
        NSApplication.sharedApplication().terminate(sender)
    }
    
}

