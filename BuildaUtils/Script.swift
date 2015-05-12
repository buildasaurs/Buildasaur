//
//  Script.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 12/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

//TODO: think about adding support for asynchronous running of scripts as well

public class Script {
    
    public typealias ScriptResponse = (terminationStatus: Int, standardOutput: String, standardError: String)
    
    //TODO: create a small project for this and github+pod it, I couldn't find a simple library for running
    //terminal scripts from Mac apps in Swift. might be useful to other people.
    public class func run(name: String, arguments: [String] = [], environment: [String: String] = [:]) -> ScriptResponse {
        
        //first resolve the name of the script to a path with `which`
        let resolved = self.runResolved("/usr/bin/which", arguments: [name], environment: [:])
        
        //which returns the path + \n, so strip the newline
        var path = resolved.standardOutput.stripTrailingNewline()
        
        //if resolving failed, just abort and propagate the failed run up
        if (resolved.terminationStatus != 0) || (count(path) == 0) {
            return resolved
        }
        
        //ok, we have a valid path, run the script
        let result = self.runResolved(path, arguments: arguments, environment: environment)
        return result
    }
    
    private class func runResolved(path: String, arguments: [String], environment: [String: String]) -> ScriptResponse {
        
        let pid = NSProcessInfo.processInfo().processIdentifier
        
        let outputPipe = NSPipe()
        let errorPipe = NSPipe()
        
        let outputFile = outputPipe.fileHandleForReading
        let errorFile = errorPipe.fileHandleForReading
        
        let task = NSTask()
        task.launchPath = path
        task.arguments = arguments
        
        var env = NSProcessInfo.processInfo().environment
        for (let index, let keyValue) in enumerate(environment) {
            env[keyValue.0] = keyValue.1
        }
        task.environment = env
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        task.launch()
        
        //blocks until script finishes.
        //TODO: think about edge cases and long running/hangings tasks - some sort of a timeout?
        task.waitUntilExit()
        
        let terminationStatus = Int(task.terminationStatus)
        let output = self.stringFromFileAndClose(outputFile)
        let error = self.stringFromFileAndClose(errorFile)
    
        return (terminationStatus, output, error)
    }
    
    private class func stringFromFileAndClose(file: NSFileHandle) -> String {
        
        let data = file.readDataToEndOfFile()
        file.closeFile()
        let output = NSString(data: data, encoding: NSUTF8StringEncoding) as String?
        return output ?? ""
    }
}

