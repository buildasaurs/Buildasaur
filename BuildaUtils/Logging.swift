//
//  Logging.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/04/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public protocol Logger {
    
    func description() -> String
    func log(message: String)
}

public class FileLogger: Logger {
    
    let filePath: NSURL
    let stream: NSOutputStream
    
    public init(filePath: NSURL) {
        self.filePath = filePath
        self.stream = NSOutputStream(URL: filePath, append: true)!
        self.stream.open()
    }
    
    deinit {
        self.stream.close()
    }
    
    public func description() -> String {
        return "File logger into file at path \(self.filePath)"
    }
    
    public func log(message: String) {
        let data: NSData = "\(message)\n".dataUsingEncoding(NSUTF8StringEncoding)!
        self.stream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
    }
}

public class ConsoleLogger: Logger {
    
    public  init() {
        //
    }
    
    public func description() -> String {
        return "Console logger"
    }
    
    public func log(message: String) {
        println(message)
    }
}

public class Log {
    
    static private var _loggers = [Logger]()
    public class func addLoggers(loggers: [Logger]) {
        for i in loggers {
            _loggers.append(i)
            println("Added logger: \(i)")
        }
    }
    
    private class func log(message: String) {
        for i in _loggers {
            i.log(message)
        }
    }
    
    public class func verbose(message: String) {
        Log.log("[VERBOSE]: " + message)
    }
    
    public class func info(message: String) {
        Log.log("[INFO]: " + message)
    }
    
    public class func error(message: String) {
        Log.log("[ERROR]: " + message)
    }
    
    public class func untouched(message: String) {
        Log.log(message)
    }
}
