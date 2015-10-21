//
//  GitRepoMetadataParser.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/21/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils
import CryptoSwift

class GitRepoMetadataParser: SourceControlFileParser {
    
    func supportedFileExtensions() -> [String] {
        return [] //takes anything
    }
    
    private typealias ScriptRun = (String) throws -> String
    
    private func parseOrigin(run: ScriptRun) throws -> String {
        
        //find the first origin ending with "(fetch)"
        let remotes = try run("git remote -v")
        let fetchRemote = remotes.split("\n").filter { $0.hasSuffix("(fetch)") }.first
        guard let remoteLine = fetchRemote else {
            throw Error.withInfo("No fetch remote found in \(remotes)")
        }
        
        //parse the fetch remote, which is
        //e.g. "origin\tgit@github.com:czechboy0/BuildaUtils.git (fetch)"
        let comps = remoteLine
            .componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "\t "))
            .filter { !$0.isEmpty }
        
        //we need at least 2 comps, take the second
        guard comps.count >= 2 else {
            throw Error.withInfo("Cannot parse origin url from components \(comps)")
        }
        
        let remote = comps[1]
        
        //we got it!
        return remote
    }
    
    private func parseProjectName(url: NSURL) throws -> String {
        
        //that's the name of the passed-in project/workspace (most of the times)
        let projectName = ((url.lastPathComponent ?? "") as NSString).stringByDeletingPathExtension
        
        guard !projectName.isEmpty else {
            throw Error.withInfo("Failed to parse project name from url \(url)")
        }
        return projectName
    }
    
    private func parseProjectPath(url: NSURL, run: ScriptRun) throws -> String {
        
        //relative path from the root of the git repo of the passed-in project
        //or workspace file
        let absolutePath = url.path!
        let relativePath = "git ls-tree --full-name --name-only HEAD \"\(absolutePath)\""
        let outPath = try run(relativePath)
        let trimmed = outPath.trim()
        guard !trimmed.isEmpty else {
            throw Error.withInfo("Failed to detect relative path of project \(url), output: \(outPath)")
        }
        return trimmed
    }
    
    private func parseProjectWCCName(url: NSURL, projectPath: String) throws -> String {
        
        //this is the folder name containing the git repo
        //it's the folder name before the project path
        //e.g. if project path is b/c/hello.xcodeproj, and the whole path
        //to the project is /Users/me/a/b/c/hello.xcodeproj, the project wcc name
        //would be "a"
        
        var projectPathComponents = projectPath.split("/")
        var pathComponents = url.pathComponents ?? []
        
        //delete from the end from both lists when components equal
        while projectPathComponents.count > 0 {
            if pathComponents.last == projectPathComponents.last {
                pathComponents.removeLast()
                projectPathComponents.removeLast()
            } else {
                throw Error.withInfo("Logic error in parsing project WCC name, url: \(url), projectPath: \(projectPath)")
            }
        }
        
        let containingFolder = pathComponents.last! + "/"
        return containingFolder
    }
    
    private func parseProjectWCCIdentifier(projectUrl: String) throws -> String {
        
        //something reproducible, but i can't figure out how Xcode generates this.
        //also - it doesn't matter, AFA it's unique
        let hashed = projectUrl.sha1().uppercaseString
        return hashed
    }
    
    func parseFileAtUrl(url: NSURL) throws -> WorkspaceMetadata {
        
        let run = { (script: String) throws -> String in
            
            let cd = "cd \"\(url.path!)\""
            let all = [cd, script].joinWithSeparator("\n")
            let response = Script.runTemporaryScript(all)
            if response.terminationStatus != 0 {
                throw Error.withInfo("Parsing git repo metadata failed, executing \"\(all)\", status: \(response.terminationStatus), output: \(response.standardOutput), error: \(response.standardError)")
            }
            return response.standardOutput
        }
        
        let origin = try self.parseOrigin(run)
        let projectName = try self.parseProjectName(url)
        let projectPath = try self.parseProjectPath(url, run: run)
        let projectWCCName = try self.parseProjectWCCName(url, projectPath: projectPath)
        let projectWCCIdentifier = try self.parseProjectWCCIdentifier(origin)
        
        return try WorkspaceMetadata(projectName: projectName, projectPath: projectPath, projectWCCIdentifier: projectWCCIdentifier, projectWCCName: projectWCCName, projectURLString: origin)
    }
}

extension String {
    
    func split(separator: String) -> [String] {
        return self.componentsSeparatedByString(separator)
    }
    
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}

