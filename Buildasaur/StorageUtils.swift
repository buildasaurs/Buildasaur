//
//  Utils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 24/01/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import Cocoa
import BuildaUtils
import XcodeServerSDK

class StorageUtils {
    
    class func openWorkspaceOrProject() -> NSURL? {
        
        var openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["xcworkspace", "xcodeproj"]
        openPanel.title = "Select your Project or Workspace"
        
        let clicked = openPanel.runModal()
        
        switch clicked {
        case NSFileHandlingPanelOKButton:
            let url = openPanel.URL
            let urlOrEmpty = url ?? NSURL()
            Log.info("Project: \(urlOrEmpty)")
            return url
        default:
            //do nothing
            Log.verbose("Dismissed open dialog")
        }
        return nil
    }
    
    class func openSSHKey(publicOrPrivate: String) -> NSURL? {
        
        var openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["", "pub"]
        openPanel.title = "Select your \(publicOrPrivate) SSH key"
        openPanel.showsHiddenFiles = true
        
        let clicked = openPanel.runModal()
        
        switch clicked {
        case NSFileHandlingPanelOKButton:
            let url = openPanel.URL
            Log.info("Key: \(url)")
            return url
        default:
            //do nothing
            Log.verbose("Dismissed open dialog")
        }
        return nil
    }
    
}

