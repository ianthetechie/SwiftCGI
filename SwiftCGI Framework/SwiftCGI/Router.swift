//
//  Router.swift
//  SwiftCGI
//
//  Created by Ian Wagner on 3/1/15.
//  Copyright (c) 2015 Ian Wagner. All rights reserved.
//

import Foundation

public class Router {
    private var subrouters: [Router] = []
    private let path: String
    private let wildcard: Bool
    private let handler: FCGIRequestHandler?
    
    public init(path: String, handleWildcardChildren wildcard: Bool, withHandler handler: FCGIRequestHandler?) {
        self.path = path
        self.wildcard = wildcard
        self.handler = handler
    }
    
    public func attachRouter(subrouter: Router) {
        subrouters.append(subrouter)
    }
    
    public func route(path: String) -> FCGIRequestHandler? {
        // TODO: Seems a bit kludgey... Functional, but kludgey...
        let components = (path as NSString).pathComponents.filter { return $0 != "/" }
        
        if components.count > 0 {
            if components.count > 1 {
                // Match on sub-routers first
                let subPath = Array<String>(components[1..<components.count]).joinWithSeparator("/")
                for subrouter in subrouters {
                    if let subhandler = subrouter.route(subPath) {
                        return subhandler
                    }
                }
            }
            
            if self.path == components.first && (components.count == 1 || self.wildcard) {
                return handler
            }
        }
        
        return nil
    }
}