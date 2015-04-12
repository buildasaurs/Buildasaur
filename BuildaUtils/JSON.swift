
//  JSON.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public class JSON {

    private class func parseDictionary(data: NSData) -> ([String: AnyObject]!, NSError!) {

        let (object: AnyObject!, error) = self.parse(data)
        return (object as [String: AnyObject]!, error)
    }

    private class func parseArray(data: NSData) -> ([AnyObject]!, NSError!) {
        
        let (object: AnyObject!, error) = self.parse(data)
        return (object as [AnyObject]!, error)
    }
    
    public class func parse(data: NSData) -> (AnyObject!, NSError!) {
        
        var parsingError: NSError?
        if let obj: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) {
            return (obj as AnyObject!, nil)
        } else {
            return (nil, parsingError)
        }
    }
}

public extension NSDictionary {
    
    public func stringForKey(key: String) -> String! {
        return self[key] as String!
    }

    public func optionalStringForKey(key: String) -> String? {

        if let string = self[key] as? String {
            return string
        } else {
            return nil
        }
    }

    public func intForKey(key: String) -> Int! {
        return self[key] as Int!
    }
    
    public func dictionaryForKey(key: String) -> NSDictionary! {
        return self[key] as NSDictionary!
    }

    public func optionalDictionaryForKey(key: String) -> NSDictionary? {

        if let dict = self[key] as? NSDictionary {
            return dict
        } else {
            return nil
        }
    }

}

