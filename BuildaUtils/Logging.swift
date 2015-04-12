//
//  Logging.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/04/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public class Log {
    
    public class func verbose(message: String) {
        println("[VERBOSE]: " + message)
    }
    
    public class func info(message: String) {
        println("[INFO]: " + message)
    }
    
    public class func error(message: String) {
        println("[ERROR]: " + message)
    }
    
    public class func untouched(message: String) {
        println(message)
    }
}
