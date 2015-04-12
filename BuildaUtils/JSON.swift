
//  JSON.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Foundation

public protocol JSONSerializable {
    init?(json: NSDictionary)
    func jsonify() -> NSDictionary
}

public class JSON {

    private class func parseDictionary(data: NSData) -> ([String: AnyObject]!, NSError!) {

        let (object: AnyObject!, error) = self.parse(data)
        return (object as! [String: AnyObject]!, error)
    }

    private class func parseArray(data: NSData) -> ([AnyObject]!, NSError!) {
        
        let (object: AnyObject!, error) = self.parse(data)
        return (object as! [AnyObject]!, error)
    }
    
    public class func parse(url: NSURL) -> (AnyObject!, NSError!) {
        
        var error: NSError?
        if let data = NSData(contentsOfURL: url, options: NSDataReadingOptions.allZeros, error: &error) {
            return self.parse(data)
        }
        return (nil, error)
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

private var formatter: NSDateFormatter!

public extension NSDictionary {
    
    public func arrayForKey<T>(key: String) -> [T]! {
        
        let array = self.arrayForKey(key)
        var newArray = [T]()
        for i in array {
            newArray.append(i as! T)
        }
        return newArray
    }
    
    public func optionalForKey<Z>(key: String) -> Z? {
        
        if let optional = self[key] as? Z {
            return optional
        }
        return nil
    }

    public func nonOptionalForKey<Z>(key: String) -> Z {
        return self.optionalForKey(key)!
    }
    
    public func optionalArrayForKey(key: String) -> NSArray? {
        return self.optionalForKey(key)
    }
    
    public func arrayForKey(key: String) -> NSArray {
        return self.nonOptionalForKey(key)
    }
    
    public func optionalStringForKey(key: String) -> String? {
        return self.optionalForKey(key)
    }
    
    public func optionalNSURLForKey(key: String) -> NSURL? {
        if let string = self.optionalStringForKey(key) {
            return NSURL(string: string)
        }
        return nil
    }

    public func stringForKey(key: String) -> String {
        return self.nonOptionalForKey(key)
    }

    public func optionalIntForKey(key: String) -> Int? {
        return self.optionalForKey(key)
    }

    public func intForKey(key: String) -> Int {
        return self.nonOptionalForKey(key)
    }
    
    public func optionalBoolForKey(key: String) -> Bool? {
        return self.optionalForKey(key)
    }

    public func boolForKey(key: String) -> Bool {
        return self.nonOptionalForKey(key)
    }
    
    public func optionalDictionaryForKey(key: String) -> NSDictionary? {
        return self.optionalForKey(key)
    }

    public func dictionaryForKey(key: String) -> NSDictionary {
        return self.nonOptionalForKey(key)
    }

    private func getFormatter() -> NSDateFormatter {
        
        if formatter == nil {
            formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
        }
        return formatter
    }

    public func optionalDateForKey(key: String) -> NSDate? {
        
        if let dateString = self.optionalStringForKey(key) {
            let date = self.getFormatter().dateFromString(dateString)
            return date
        }
        return nil
    }

    public func dateForKey(key: String) -> NSDate {
        return self.optionalDateForKey(key)!
    }
    
    public func optionalDoubleForKey(key: String) -> Double? {
        return self.optionalForKey(key)
    }

    public func doubleForKey(key: String) -> Double {
        return self.nonOptionalForKey(key)
    }
    
}

public extension NSMutableDictionary {
    
    public func optionallyAddValueForKey(value: AnyObject?, key: String) {
        if let value: AnyObject = value {
            self[key] = value
        }
    }
}

