//
//  CommonExtensions.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 17/02/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

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
