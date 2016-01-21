//
//  Logging.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 18/07/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class Logging {
    
    public class func setup(persistence: Persistence, alsoIntoFile: Bool) {
        
        let path = persistence.fileURLWithName("Builda.log", intention: .Writing, isDirectory: false)
        
        var loggers = [Logger]()
        
        let consoleLogger = ConsoleLogger()
        loggers.append(consoleLogger)
        
        if alsoIntoFile {
            let fileLogger = FileLogger(fileURL: path)
            fileLogger.fileSizeCap = 1024 * 1024 * 10 // 10MB
            loggers.append(fileLogger)
        }
        
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
}