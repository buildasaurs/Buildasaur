//
//  AppDelegate.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa

/*
TODO: Keychain: GitHub token

Please report any crashes on GitHub, I may optionally ask you to email them to me. Thanks!
You can find them at ~/Library/Logs/DiagnosticReports/Buildasaur-*

*/

import BuildaCIServer

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var server: XcodeServer?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        
        StorageManager.sharedInstance.stop()
    }
    
}

