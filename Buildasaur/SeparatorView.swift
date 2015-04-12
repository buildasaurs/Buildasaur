//
//  SeparatorView.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 07/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit

class SeparatorView: NSView {
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.wantsLayer = true
        self.layer!.backgroundColor = NSColor.lightGrayColor().CGColor
    }
    
}