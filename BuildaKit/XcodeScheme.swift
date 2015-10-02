//
//  XcodeScheme.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 02/10/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

extension NSURL {
    
    public var fileNameNoExtension: String? {
        return ((self.lastPathComponent ?? "") as NSString).stringByDeletingPathExtension
    }
}

public struct XcodeScheme {
    
    public var name: String {
        return self.path.fileNameNoExtension!
    }
    
    public let path: NSURL
    public let ownerProjectOrWorkspace: NSURL
}
