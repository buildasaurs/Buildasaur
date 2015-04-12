//
//  XcodeServerFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class XcodeServerFactory {
    
    public class func server(config: XcodeServerConfig) -> XcodeServer {
        
        let endpoints = XcodeServerEndPoints(serverConfig: config)
        let server = XcodeServer(config: config, endpoints: endpoints)
        
        return server
    }
}
