//
//  LoginItem.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/14/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

//manages adding/removing Buildasaur as a login item

public class LoginItem {
    
    public init() { }
    
    public var isLaunchItem: Bool {
        get {
            return self.hasPlistInstalled()
        }
        set {
            if newValue {
                do {
                    try self.addLaunchItemPlist()
                } catch {
                    Log.error("Error while adding login item: \(error)")
                }
            } else {
                self.removeLaunchItemPlist()
            }
        }
    }
    
    private func hasPlistInstalled() -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(self.launchItemPlistURL().path!)
    }
    
    private func launchItemPlistURL() -> NSURL {
        let path = ("~/Library/LaunchAgents/com.honzadvorsky.Buildasaur.plist" as NSString).stringByExpandingTildeInPath
        let url = NSURL(fileURLWithPath: path, isDirectory: false)
        return url
    }
    
    private func currentBinaryPath() -> String {
        
        let processInfo = NSProcessInfo.processInfo()
        let launchPath = processInfo.arguments.first!
        return launchPath
    }
    
    private func launchItemPlistWithLaunchPath(launchPath: String) throws -> String {
        
        let plistStringUrl = NSBundle.mainBundle().URLForResource("launch_item", withExtension: "plist")!
        let plistString = try String(contentsOfURL: plistStringUrl)
        
        //replace placeholder with launch path
        let patchedPlistString = plistString.stringByReplacingOccurrencesOfString("LAUNCH_PATH_PLACEHOLDER", withString: launchPath)
        return patchedPlistString
    }
    
    public func removeLaunchItemPlist() {
        _ = try? NSFileManager.defaultManager().removeItemAtURL(self.launchItemPlistURL())
    }
    
    public func addLaunchItemPlist() throws {
        let launchPath = self.currentBinaryPath()
        let contents = try self.launchItemPlistWithLaunchPath(launchPath)
        let url = self.launchItemPlistURL()
        try contents.writeToURL(url, atomically: true, encoding: NSUTF8StringEncoding)
    }
    
}
