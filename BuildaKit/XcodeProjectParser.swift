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
    
    static private var sourceControlFileParsers: [SourceControlFileParser] = [
        CheckoutFileParser(),
        BlueprintFileParser()
    ]
    
    private class func firstItemMatchingTestRecursive(url: NSURL, test: (itemUrl: NSURL) -> Bool) throws -> NSURL? {
        
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
            
            let contents = try fm.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
            for i in contents {
                if let foundUrl = try self.firstItemMatchingTestRecursive(i, test: test) {
                    return foundUrl
                }
            }
        }
        return nil
    }
    
    private class func firstItemMatchingTest(url: NSURL, test: (itemUrl: NSURL) -> Bool) throws -> NSURL? {
        
        return try self.allItemsMatchingTest(url, test: test).first
    }

    private class func allItemsMatchingTest(url: NSURL, test: (itemUrl: NSURL) -> Bool) throws -> [NSURL] {
        
        let fm = NSFileManager.defaultManager()
        let contents = try fm.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
        
        let filtered = contents.filter(test)
        return filtered
    }
    
    private class func findCheckoutOrBlueprintUrl(projectOrWorkspaceUrl: NSURL) throws -> NSURL {
        
        if let found = try self.firstItemMatchingTestRecursive(projectOrWorkspaceUrl, test: { (itemUrl: NSURL) -> Bool in
            
            let pathExtension = itemUrl.pathExtension
            return pathExtension == "xccheckout" || pathExtension == "xcscmblueprint"
        }) {
            return found
        }
        throw Error.withInfo("No xccheckout or xcscmblueprint file found")
    }
    
    private class func parseCheckoutOrBlueprintFile(url: NSURL) throws -> WorkspaceMetadata {
        
        let pathExtension = url.pathExtension!
        
        let maybeParser = self.sourceControlFileParsers.filter {
            Set($0.supportedFileExtensions()).contains(pathExtension)
        }.first
        guard let parser = maybeParser else {
            throw Error.withInfo("Could not find a parser for path extension \(pathExtension)")
        }
        
        let parsedWorkspace = try parser.parseFileAtUrl(url)
        return parsedWorkspace
    }
    
    public class func parseRepoMetadataFromProjectOrWorkspaceURL(url: NSURL) throws -> WorkspaceMetadata {
        
        do {
            let checkoutUrl = try self.findCheckoutOrBlueprintUrl(url)
            let parsed = try self.parseCheckoutOrBlueprintFile(checkoutUrl)
            return parsed
        } catch {
            throw Error.withInfo("Cannot find the Checkout/Blueprint file, please make sure to open this project in Xcode at least once (it will generate the required Checkout/Blueprint file) and create at least one Bot from Xcode. Then please try again. Create an issue on GitHub is this issue persists. (Error \((error as NSError).localizedDescription))")
        }
    }
    
    public class func sharedSchemesFromProjectOrWorkspaceUrl(url: NSURL) -> [XcodeScheme] {
        
        var projectUrls: [NSURL]
        if self.isWorkspaceUrl(url) {
            //first parse project urls from workspace contents
            projectUrls = self.projectUrlsFromWorkspace(url) ?? [NSURL]()
            
            //also add the workspace's url, it might own some schemes as well
            projectUrls.append(url)
            
        } else {
            //this already is a project url, take just that
            projectUrls = [url]
        }
        
        //we have the project urls, now let's parse schemes from each of them
        let schemes = projectUrls.map {
            return self.sharedSchemeUrlsFromProjectUrl($0)
        }.reduce([XcodeScheme](), combine: { (arr, newSchemes) -> [XcodeScheme] in
            return arr + newSchemes
        })
        
        return schemes
    }
    
    private class func sharedSchemeUrlsFromProjectUrl(url: NSURL) -> [XcodeScheme] {
        
        //the structure is
        //in a project file, if there are any shared schemes, they will be in
        //xcshareddata/xcschemes/*
        do {
            if let sharedDataFolder = try self.firstItemMatchingTest(url,
                test: { (itemUrl: NSURL) -> Bool in
                    
                    return itemUrl.lastPathComponent == "xcshareddata"
            }) {
                
                if let schemesFolder = try self.firstItemMatchingTest(sharedDataFolder,
                    test: { (itemUrl: NSURL) -> Bool in
                        
                        return itemUrl.lastPathComponent == "xcschemes"
                }) {
                    //we have the right folder, yay! just filter all files ending with xcscheme
                    let schemeUrls = try self.allItemsMatchingTest(schemesFolder, test: { (itemUrl: NSURL) -> Bool in
                        let ext = itemUrl.pathExtension ?? ""
                        return ext == "xcscheme"
                    })
                    let schemes = schemeUrls.map { XcodeScheme(path: $0, ownerProjectOrWorkspace: url) }
                    return schemes
                }
            }
        } catch {
            Log.error(error)
        }
        return []
    }
    
    private class func isProjectUrl(url: NSURL) -> Bool {
        return url.pathExtension == "xcodeproj"
    }

    private class func isWorkspaceUrl(url: NSURL) -> Bool {
        return url.pathExtension == "xcworkspace"
    }

    private class func projectUrlsFromWorkspace(url: NSURL) -> [NSURL]? {
        
        assert(self.isWorkspaceUrl(url), "Url \(url) is not a workspace url")
        
        do {
            let urls = try XcodeProjectXMLParser.parseProjectsInsideOfWorkspace(url)
            return urls
        } catch {
            Log.error("Couldn't load workspace at path \(url) with error \(error)")
            return nil
        }
    }
    
    private class func parseSharedSchemesFromProjectURL(url: NSURL) -> (schemeUrls: [NSURL]?, error: NSError?) {
        
        return (schemeUrls: [NSURL](), error: nil)
    }
    
}

