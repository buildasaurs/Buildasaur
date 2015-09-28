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
    
    public class func loadJSONFromUrl(url: NSURL) throws -> AnyObject? {
        
        let data = try NSData(contentsOfURL: url, options: NSDataReadingOptions())
        let json: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        return json
    }
    
    public class func saveJSONToUrl(json: AnyObject, url: NSURL) throws {
        
        let data = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted)
        try data.writeToURL(url, options: NSDataWritingOptions.DataWritingAtomic)
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
        do {
            try fm.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Failed to create a folder in Builda's Application Support folder \(url), error \(error)")
        }
    }
    
    public class func buildaApplicationSupportFolderURL() -> NSURL {
        
        let fm = NSFileManager.defaultManager()
        if let appSupport = fm.URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains:NSSearchPathDomainMask.UserDomainMask).first {
            
//            let folderName = "Buildasaur"
            let folderName = "Buildasaur-Debug"
            let buildaAppSupport = appSupport.URLByAppendingPathComponent(folderName, isDirectory: true)
            
            //ensure it exists
            do {
                try fm.createDirectoryAtURL(buildaAppSupport, withIntermediateDirectories: true, attributes: nil)
                return buildaAppSupport
            } catch {
                Log.error("Failed to create Builda's Application Support folder, error \(error)")
            }
        }
        
        assertionFailure("Couldn't access Builda's persistence folder, aborting")
        return NSURL()
    }
    
    public class func iterateThroughFilesInFolder(folderUrl: NSURL, visit: (url: NSURL) -> ()) {
        
        let fm = NSFileManager.defaultManager()
        do {
            let contents = try fm.contentsOfDirectoryAtURL(folderUrl, includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants])
            contents.forEach { visit(url: $0) }
            
        } catch {
            Log.error("Couldn't read folder \(folderUrl), error \(error)")
        }
    }
    
}
