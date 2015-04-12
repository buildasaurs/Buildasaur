//
//  Errors.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 07/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public enum BuildaError: String {
    case UnknownError = "Unknown error"
}

public class Errors {
    
    public class func errorFromType(type: BuildaError) -> NSError {
        
        return self.errorWithInfo(type.rawValue)
    }
    
    public class func errorWithInfo(info: String?, internalError: NSError? = nil, userInfo: NSDictionary? = nil) -> NSError {
        
        var finalInfo = NSMutableDictionary()
        if let info = info {
            finalInfo[NSLocalizedDescriptionKey] = info
        }
        if let internalError = internalError {
            finalInfo["encountered_error"] = internalError
        }
        if let userInfo = userInfo {
            finalInfo.addEntriesFromDictionary(userInfo as [NSObject : AnyObject])
        }
        
        return NSError(domain: "com.honzadvorsky.Buildasaur", code: 0, userInfo: finalInfo as [NSObject : AnyObject])
    }
    
}
