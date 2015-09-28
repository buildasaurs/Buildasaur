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
    
    class func loadDictionaryFromFile<T>(name: String) -> T? {
        return self.loadDataFromFile(name, process: { (json) -> T? in
            
            guard let contents = json as? T else { return nil }
            return contents
        })
    }
    
    class func loadArrayFromFile<T>(name: String, convert: (json: NSDictionary) throws -> T?) -> [T]? {
        
        return self.loadDataFromFile(name, process: { (json) -> [T]? in
            
            guard let json = json as? [NSDictionary] else { return nil }
            
            let allItems = json.map { (item) -> T? in
                do { return try convert(json: item) } catch { return nil }
            }
            let parsedItems = allItems.filter { $0 != nil }.map { $0! }
            if parsedItems.count != allItems.count {
                Log.error("Some \(name) failed to parse, will be ignored.")
                //maybe show a popup?
            }
            return parsedItems
        })
    }
    
    class func loadArrayFromFile<T: JSONSerializable>(name: String) -> [T]? {
        
        return self.loadArrayFromFile(name) { try T(json: $0) }
    }
    
    class func loadDataFromFile<T>(name: String, process: (json: AnyObject?) -> T?) -> T? {
        let configUrl = Persistence.getFileInAppSupportWithName(name, isDirectory: false)
        do {
            let json = try Persistence.loadJSONFromUrl(configUrl)
            guard let contents = process(json: json) else { return nil }
            return contents
        } catch {
            //file not found
            if (error as NSError).code != 260 {
                Log.error("Failed to read \(name), error \(error). Will be ignored. Please don't play with the persistence :(")
            }
            return nil
        }
    }
    
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
