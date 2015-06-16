//
//  MockHelpers.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 17/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

class MockHelpers {
    
    class func loadSampleIntegration() -> NSMutableDictionary {
        
        let bundle = NSBundle(forClass: MockHelpers.self)
        if
            let url = bundle.URLForResource("sampleFinishedIntegration", withExtension: "json"),
            let data = NSData(contentsOfURL: url),
            let obj = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSMutableDictionary
        {
            return obj
            
        } else {
            assertionFailure("no sample integration json")
        }
        return NSMutableDictionary()
    }
    
}
