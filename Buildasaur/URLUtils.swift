//
//  URLUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/13/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa

func openLink(link: String) {
    
    if let url = NSURL(string: link) {
        NSWorkspace.sharedWorkspace().openURL(url)
    }
}
