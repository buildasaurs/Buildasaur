//
//  AppDelegate.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa

/*
Please report any crashes on GitHub, I may optionally ask you to email them to me. Thanks!
You can find them at ~/Library/Logs/DiagnosticReports/Buildasaur-*
Also, you can find the log at ~/Library/Application Support/Buildasaur/Builda.log
*/

import BuildaUtils
import XcodeServerSDK
import BuildaKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let menuItemManager = MenuItemManager()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        Logging.setup(alsoIntoFile: true)
        self.menuItemManager.setupMenuBarItem()
    }

    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        self.showMainWindow()
        return true
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        
        self.showMainWindow()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        
        StorageManager.sharedInstance.stop()
    }
    
    //MARK: Showing Window on Reactivation
    
    func showMainWindow(){
        
        NSApp.activateIgnoringOtherApps(true)
        
        //first window. i wish there was a nicer way (please some tell me there is)
        if let window = NSApplication.sharedApplication().windows.first {
            window.makeKeyAndOrderFront(self)
        }
    }
}

