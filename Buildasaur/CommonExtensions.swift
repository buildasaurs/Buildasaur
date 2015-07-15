//
//  CommonExtensions.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 17/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

func firstNonNil<T>(objects: [T?]) -> T? {
    for i in objects {
        if let i = i {
            return i
        }
    }
    return nil
}

extension Set {
    
    func filterSet(includeElement: (Element) -> Bool) -> Set<Element> {
        return Set(self.filter(includeElement))
    }
}

extension Array {
    
    func indexOfFirstObjectPassingTest(test: (Element) -> Bool) -> Array<Element>.Index? {
        
        for (idx, obj) in self.enumerate() {
            if test(obj) {
                return idx
            }
        }
        return nil
    }
}

extension Array {
    
    func mapVoidAsync(transformAsync: (item: Element, itemCompletion: () -> ()) -> (), completion: () -> ()) {
        self.mapAsync(transformAsync, completion: { (_) -> () in
            completion()
        })
    }
    
    func mapAsync<U>(transformAsync: (item: Element, itemCompletion: (U) -> ()) -> (), completion: ([U]) -> ()) {
        
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
    func toDictionary(key: (Element) -> String) -> [String: Element] {
        
        var dict = [String: Element]()
        for i in self {
            dict[key(i)] = i
        }
        return dict
    }
}

