//
//  Server.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 14/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class HTTPServer : NSObject {
    
    public let http: HTTP
    
    public init(http: HTTP? = nil) {
        
        self.http = http ?? HTTP()
    }
    
}
