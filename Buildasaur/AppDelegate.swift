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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        self.setupLogging()
    }
    
    func setupLogging() {
        
        let path = Persistence.buildaApplicationSupportFolderURL().URLByAppendingPathComponent("Builda.log", isDirectory: false)
        let fileLogger = FileLogger(filePath: path)
        let consoleLogger = ConsoleLogger()
        let loggers: [Logger] = [
            consoleLogger,
            fileLogger
        ]
        Log.addLoggers(loggers)
        let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
        let ascii =
        " ____        _ _     _\n" +
        "|  _ \\      (_) |   | |\n" +
        "| |_) |_   _ _| | __| | __ _ ___  __ _ _   _ _ __\n" +
        "|  _ <| | | | | |/ _` |/ _` / __|/ _` | | | | '__|\n" +
        "| |_) | |_| | | | (_| | (_| \\__ \\ (_| | |_| | |\n" +
        "|____/ \\__,_|_|_|\\__,_|\\__,_|___/\\__,_|\\__,_|_|\n"
        
        Log.untouched("*\n*\n*\n\(ascii)\nBuildasaur \(version) launched at \(NSDate()).\n*\n*\n*\n")
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        
        StorageManager.sharedInstance.stop()
    }
    
}

