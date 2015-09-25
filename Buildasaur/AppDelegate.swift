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
import Alamofire

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSURLSessionDelegate {
    
    let menuItemManager = MenuItemManager()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        self.menuItemManager.setupMenuBarItem()
        self.startPolling1()
    }
    
    var af: Alamofire.Manager!
    
    func timestamp() -> Int {
        return Int(NSDate().timeIntervalSince1970)*1000
    }
    
    func startPolling1() {
        let st = ServerTrustPolicyManager(policies: ["localhost": .DisableEvaluation])
        let af = Alamofire.Manager(serverTrustPolicyManager: st)
        self.af = af
        
        af
            .request(.GET, "https://localhost/xcode/internal/socket.io/1/?t=\(timestamp)")
            .responseString { (req, res, result) -> Void in
                print("Received: \(result)")
                
                if let msg = result.value {
                    //parse object id and polling techniques
                    let id = msg.componentsSeparatedByString(":").first!
                    self.poll(id)
                }
        }
    }
    
    func poll(id: String) {
        
        let timestamp = self.timestamp()
        let url = "https://localhost/xcode/internal/socket.io/1/xhr-polling/\(id)?t=\(timestamp)"
        self.af
            .request(.GET, url)
            .responseString { (req, res, result) -> Void in
                if let str = result.value {
                    print("Received: \(str)")
                    self.poll(id)
                }
        }
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

