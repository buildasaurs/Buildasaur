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
    
    func filterSet(includeElement: (T) -> Bool) -> Set<T> {
        return Set(filter(self, includeElement))
    }
}

extension Array {
    
    func indexOfFirstObjectPassingTest(test: (T) -> Bool) -> Array<T>.Index? {
        
        for (idx, obj) in enumerate(self) {
            if test(obj) {
                return idx
            }
        }
        return nil
    }
}

extension Array {
    
    func mapVoidAsync(transformAsync: (item: T, itemCompletion: () -> ()) -> (), completion: () -> ()) {
        self.mapAsync(transformAsync, completion: { (_) -> () in
            completion()
        })
    }
    
    func mapAsync<U>(transformAsync: (item: T, itemCompletion: (U) -> ()) -> (), completion: ([U]) -> ()) {
        
        let group = dispatch_group_create()
        var returnedValueMap = [Int: U]()
        
        for (index, element) in enumerate(self) {
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
    func toDictionary(key: (T) -> String) -> [String: T] {
        
        var dict = [String: T]()
        for i in self {
            dict[key(i)] = i
        }
        return dict
    }
}

