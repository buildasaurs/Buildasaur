//
//  AppDelegate.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/12/2014.
//  Copyright (c) 2014 Honza Dvorsky. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        self.initializeRefresh()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func initializeRefresh() {
        
//        let secondsInterval = 20
//        var timer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: Selector("pollForUpdates"), userInfo: nil, repeats: true)
//        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }



}

