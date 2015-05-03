//
//  Extensions.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 03/05/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public extension Double {
    
    public func clipTo(numberOfDigits: Int) -> Double {
        
        let multiplier = pow(10.0, Double(numberOfDigits))
        return Double(Int(self * multiplier)) / multiplier
    }
}
