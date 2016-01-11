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
    private let handler: RequestHandler?
    
    public init(path: String, handleWildcardChildren wildcard: Bool, withHandler handler: RequestHandler?) {
        self.path = path
        self.wildcard = wildcard
        self.handler = handler
    }
    
    public func attachRouter(subrouter: Router) {
        subrouters.append(subrouter)
    }
    
    public func route(pathToRoute: String) -> RequestHandler? {
        // TODO: Seems a bit kludgey... Functional, but kludgey...
        
        // Ignore stray slashes
        let components = (pathToRoute as NSString).pathComponents.filter { return $0 != "/" }
        
//        if components.count > 0 {
            if components.count > 1 {
                // Match greedily on sub-routers first
                let subPath = Array<String>(components[1..<components.count]).joinWithSeparator("/")
                for subrouter in subrouters {
                    if let subhandler = subrouter.route(subPath) {
                        return subhandler
                    }
                }
            }
        
            let pathMatchesFirstComponent = self.path == components.first
            if (pathMatchesFirstComponent && (components.count == 1 || self.wildcard)) || (components.count == 0 && self.path == "/" && self.wildcard)  {
                return handler
            }
//        }
        
        return nil
    }
}