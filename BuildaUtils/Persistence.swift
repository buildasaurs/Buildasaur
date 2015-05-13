//
//  Persistence.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 07/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class Persistence {
    
    public class func loadJSONFromUrl(url: NSURL) -> (AnyObject?, NSError?) {
        
        var error: NSError?
        if let data = NSData(contentsOfURL: url, options: NSDataReadingOptions.allZeros, error: &error) {
            
            if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &error) {
                return (json, nil)
            }
        }
        return (nil, error)
    }
    
    public class func saveJSONToUrl(json: AnyObject, url: NSURL) -> (Bool, NSError?) {
        
        var error: NSError?
        if let data = NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted, error: &error) {
            
            if (data.writeToURL(url, options: NSDataWritingOptions.DataWritingAtomic, error: &error)) {
                return (true, nil)
            }
        }
        return (false, error)
    }
    
    public class func getFileInAppSupportWithName(name: String, isDirectory: Bool) -> NSURL {
        
        let root = self.buildaApplicationSupportFolderURL()
        let url = root.URLByAppendingPathComponent(name, isDirectory: isDirectory)
        if isDirectory {
            self.createFolderIfNotExists(url)
        }
        return url
    }
        
    public class func createFolderIfNotExists(url: NSURL) {
        
        let fm = NSFileManager.defaultManager()
        
        var error: NSError?
        let success = fm.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil, error: &error)
        assert(success, "Failed to create a folder in Builda's Application Support folder \(url), error \(error)")
    }
    
    public class func buildaApplicationSupportFolderURL() -> NSURL {
        
        let fm = NSFileManager.defaultManager()
        if let appSupport = fm.URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains:NSSearchPathDomainMask.UserDomainMask).first as? NSURL {
            
            let buildaAppSupport = appSupport.URLByAppendingPathComponent("Buildasaur", isDirectory: true)
            
            //ensure it exists
            var error: NSError?
            if fm.createDirectoryAtURL(buildaAppSupport, withIntermediateDirectories: true, attributes: nil, error: &error) {
                return buildaAppSupport
                
            } else {
                Log.error("Failed to create Builda's Application Support folder, error \(error)")
            }
        }
        
        assertionFailure("Couldn't access Builda's persistence folder, aborting")
        return NSURL()
    }
    
    public class func iterateThroughFilesInFolder(folderUrl: NSURL, visit: (url: NSURL) -> ()) {
        
        let fm = NSFileManager.defaultManager()
        var error: NSError?
        if let contents = fm.contentsOfDirectoryAtURL(folderUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles | NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants, error: &error) as? [NSURL] {
            contents.map { visit(url: $0) }
        } else {
            Log.error("Couldn't read folder \(folderUrl), error \(error)")
        }
    }
    
}
