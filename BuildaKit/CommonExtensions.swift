//
//  CommonExtensions.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 17/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public func firstNonNil<T>(objects: [T?]) -> T? {
    for i in objects {
        if let i = i {
            return i
        }
    }
    return nil
}

extension Set {
    
    public func filterSet(includeElement: (Element) -> Bool) -> Set<Element> {
        return Set(self.filter(includeElement))
    }
}

extension Array {
    
    public func indexOfFirstObjectPassingTest(test: (Element) -> Bool) -> Array<Element>.Index? {
        
        for (idx, obj) in self.enumerate() {
            if test(obj) {
                return idx
            }
        }
        return nil
    }
    
    public func firstObjectPassingTest(test: (Element) -> Bool) -> Element? {
        for item in self {
            if test(item) {
                return item
            }
        }
        return nil
    }
}

extension Array {
    
    public func mapVoidAsync(transformAsync: (item: Element, itemCompletion: () -> ()) -> (), completion: () -> ()) {
        self.mapAsync(transformAsync, completion: { (_) -> () in
            completion()
        })
    }
    
    public func mapAsync<U>(transformAsync: (item: Element, itemCompletion: (U) -> ()) -> (), completion: ([U]) -> ()) {
        
        let group = dispatch_group_create()
        var returnedValueMap = [Int: U]()
        
        for (index, element) in self.enumerate() {
            dispatch_group_enter(group)
            transformAsync(item: element, itemCompletion: {
                (returned: U) -> () in
                returnedValueMap[index] = returned
                dispatch_group_leave(group)
            })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            
            //we have all the returned values in a map, put it back into an array of Us
            var returnedValues = [U]()
            for i in 0 ..< returnedValueMap.count {
                returnedValues.append(returnedValueMap[i]!)
            }
            completion(returnedValues)
        }
    }
}

extension Array {
    
    //dictionarify an array for fast lookup by a specific key
    public func toDictionary(key: (Element) -> String) -> [String: Element] {
        
        var dict = [String: Element]()
        for i in self {
            dict[key(i)] = i
        }
        return dict
    }
}

public enum NSDictionaryParseError: ErrorType {
    case MissingValueForKey(key: String)
    case WrongTypeOfValueForKey(key: String, value: AnyObject)
}

extension NSDictionary {
    
    public func get<T>(key: String) throws -> T {
        
        guard let value = self[key] else {
            throw NSDictionaryParseError.MissingValueForKey(key: key)
        }
        
        guard let typedValue = value as? T else {
            throw NSDictionaryParseError.WrongTypeOfValueForKey(key: key, value: value)
        }
        return typedValue
    }
    
    public func getOptionally<T>(key: String) throws -> T? {
        
        guard let value = self[key] else {
            return nil
        }
        
        guard let typedValue = value as? T else {
            throw NSDictionaryParseError.WrongTypeOfValueForKey(key: key, value: value)
        }
        return typedValue
    }
}

extension Dictionary {
    
    public mutating func merge<S: SequenceType where S.Generator.Element == (Key,Value)> (other: S) {
        for (key, value) in other {
            self[key] = value
        }
    }
}

extension Array {
    
    public func dictionarifyWithKey(key: (item: Element) -> String) -> [String: Element] {
        var dict = [String: Element]()
        self.forEach { dict[key(item: $0)] = $0 }
        return dict
    }
}

extension String {
    
    //returns nil if string is empty
    public func nonEmpty() -> String? {
        return self.isEmpty ? nil : self
    }
}

public func delayClosure(delay: Double, closure: () -> ()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(),
        closure)
}


