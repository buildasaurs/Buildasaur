//
//  ExtensionTests.swift
//  Buildasaur
//
//  Created by Anton Domashnev on 25/06/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class ExtensionTests: XCTestCase {
    
    func testMergeShouldMergeTwoDictionaries() {
        var dictionary1: [String: String] = ["A": "B", "A1": "B1", "A2": "B2" ]
        let dictionary2: [String: String] = ["A2": "B2", "A3": "B3", "A4": "B4" ]
        let expectedMergedDictionary: [String: String] = ["A": "B", "A1": "B1", "A2": "B2", "A3": "B3", "A4": "B4" ]
        
        dictionary1.merge(dictionary2)
        
        XCTAssertEqual(dictionary1, expectedMergedDictionary)
    }
    
}
