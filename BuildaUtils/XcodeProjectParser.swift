//
//  XcodeProjectParser.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 24/01/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public class XcodeProjectParser {
    
    private class func firstItemMatchingTestRecursive(url: NSURL, test: (itemUrl: NSURL) -> Bool) -> NSURL? {
        
        let fm = NSFileManager.defaultManager()
        
        if let path = url.path {
            
            var isDir: ObjCBool = false
            let exists = fm.fileExistsAtPath(path, isDirectory: &isDir)
            if !exists {
                return nil
            }
            
            if !isDir {
                //not dir, test
                return test(itemUrl: url) ? url : nil
            }
            
            var error: NSError?
            if let contents = fm.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.allZeros, error: &error) as? [NSURL] {
                for i in contents {
                    if let foundUrl = self.firstItemMatchingTestRecursive(i, test: test) {
                        return foundUrl
                    }
                }
            }
        }
        return nil
    }
    
    private class func firstItemMatchingTest(url: NSURL, test: (itemUrl: NSURL) -> Bool) -> NSURL? {
        
        return self.allItemsMatchingTest(url, test: test).first
    }

    private class func allItemsMatchingTest(url: NSURL, test: (itemUrl: NSURL) -> Bool) -> [NSURL] {
        
        let fm = NSFileManager.defaultManager()
        var error: NSError?
        if let contents = fm.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.allZeros, error: &error) as? [NSURL] {
            
            let filtered = contents.filter(test)
            return filtered
        }
        
        return [NSURL]()
    }
    
    private class func findCheckoutUrl(workspaceUrl: NSURL) -> NSURL? {
        
        return self.firstItemMatchingTestRecursive(workspaceUrl, test: { (itemUrl: NSURL) -> Bool in
            
            return itemUrl.pathExtension == "xccheckout";
        })
    }
    
    private class func parseCheckoutFile(url: NSURL) -> NSDictionary? {

        return NSDictionary(contentsOfURL: url)
    }
    
    public class func parseRepoMetadataFromProjectOrWorkspaceURL(url: NSURL) -> (NSDictionary?, NSError?) {
        
        let workspaceUrl = url
        
        if let checkoutUrl = self.findCheckoutUrl(workspaceUrl) {
            //we have the checkout url
            
            if let parsed = self.parseCheckoutFile(checkoutUrl) {
                return (parsed, nil)
            } else {
                let error = Errors.errorWithInfo("Cannot parse the checkout file at path \(checkoutUrl)")
                return (nil, error)
            }
        }
        //no checkout, what to do?
        let error = Errors.errorWithInfo("Cannot find the Checkout file, please make sure to open this project in Xcode at least once (it will generate the required Checkout file). Then try again.")
        return (nil, error)
    }
    
    public class func sharedSchemeUrlsFromProjectOrWorkspaceUrl(url: NSURL) -> [NSURL] {
        
        let projectUrls: [NSURL]
        if self.isWorkspaceUrl(url) {
            //first parse project urls from workspace contents
            projectUrls = self.projectUrlsFromWorkspace(url) ?? [NSURL]()
        } else {
            //this already is a project url, take just that
            projectUrls = [url]
        }
        
        //we have the project urls, now let's parse schemes from each of them
        let schemeUrls = projectUrls.map {
            self.sharedSchemeUrlsFromProjectUrl($0)
        }.reduce([NSURL](), combine: { (arr, newUrls) -> [NSURL] in
            arr + newUrls
        })
        
        return schemeUrls
    }
    
    private class func sharedSchemeUrlsFromProjectUrl(url: NSURL) -> [NSURL] {
        
        //the structure is
        //in a project file, if there are any shared schemes, they will be in
        //xcshareddata/xcschemes/*
        if let sharedDataFolder = self.firstItemMatchingTest(url,
            test: { (itemUrl: NSURL) -> Bool in
                
            return itemUrl.lastPathComponent == "xcshareddata"
        }) {
            
            if let schemesFolder = self.firstItemMatchingTest(sharedDataFolder,
                test: { (itemUrl: NSURL) -> Bool in
                    
                return itemUrl.lastPathComponent == "xcschemes"
            }) {
                //we have the right folder, yay! just filter all files ending with xcscheme
                let schemes = self.allItemsMatchingTest(schemesFolder, test: { (itemUrl: NSURL) -> Bool in
                    let ext = itemUrl.pathExtension ?? ""
                    return ext == "xcscheme"
                })
                return schemes
            }
        }
        
        return [NSURL]()
    }
    
    private class func isProjectUrl(url: NSURL) -> Bool {
        return url.absoluteString!.hasSuffix(".xcodeproj")
    }

    private class func isWorkspaceUrl(url: NSURL) -> Bool {
        return url.absoluteString!.hasSuffix(".xcworkspace")
    }

    private class func projectUrlsFromWorkspace(url: NSURL) -> [NSURL]? {
        assert(self.isWorkspaceUrl(url), "Url \(url) is not a workspace url")
        
        //parse the workspace contents url and get the urls of the contained projects
        let contentsUrl = url.URLByAppendingPathComponent("contents.xcworkspacedata")
        
        var readingError: NSError?
        if let contentsData = NSFileManager.defaultManager().contentsAtPath(contentsUrl.path!) {
            
            if let stringContents = NSString(data: contentsData, encoding: NSUTF8StringEncoding) {
                //parse by lines
                let components = stringContents.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) as! [String]
                
                let projectRelativePaths = components.map {
                    (line: String) -> String? in
                    
                    let range1 = line.rangeOfString("group:")
                    let range2 = line.rangeOfString("\">", options: NSStringCompareOptions.BackwardsSearch)
                    if let range1 = range1, let range2 = range2 {
                        let start = range1.endIndex
                        let end = range2.startIndex
                        return line.substringWithRange(Range<String.Index>(start: start, end: end))
                    }
                    return nil
                }.filter {
                    return $0 != nil
                }.map {
                    return $0!
                }

                //we now have relative paths, let's make them absolute
                let absolutePaths = projectRelativePaths.map {
                    return url.URLByAppendingPathComponent("..").URLByAppendingPathComponent($0)
                }
                
                //ok, we're done, return 
                return absolutePaths
            }
        }
        Log.error("Couldn't load contents of workspace \(url)")
        return nil
    }
    
    private class func parseSharedSchemesFromProjectURL(url: NSURL) -> (schemeUrls: [NSURL]?, error: NSError?) {
        
        
        
        return (schemeUrls: [NSURL](), error: nil)
    }
    
}

