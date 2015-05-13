//
//  SSHKeyVerification.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 13/05/15.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public class SSHKeyVerification {
    
    public class func getGitVersion() -> Script.ScriptResponse {
        
        let response = Script.run("/usr/bin/git", arguments: ["--version"])
        return response
    }
    
    public class func verifyGitVersion(response: Script.ScriptResponse) -> (Bool, String) {
        
        let versionString = response.standardOutput.stripTrailingNewline()
        let comps = versionString.componentsSeparatedByString(" ")
        
        if comps.count >= 3 {
            let version = comps[2]
            if version >= "2.3.0" {
                return (true, "")
            }
            return (false, "Git version >= 2.3 required, found \(version)")
        }
        return (false, "Couldn't verify git version")
    }
    
    public class func verifyKeys(path: String, repoSSHUrl: String) -> Script.ScriptResponse {
        
        let git = self.getGitVersion()
        let (gitVersionSuccess, gitVersionErrorString) = self.verifyGitVersion(git)
        if !gitVersionSuccess {
            Log.error("Insufficient git version. Found \(git.standardOutput.stripTrailingNewline()), we require at least 2.3")
            return (1, "", gitVersionErrorString)
        }
        
        //create a temp script, because NSTask is being difficult and doesn't play nice with environment variables,
        //which we need for forcing SSH keys from a specific path to verify they are valid for your repo. sigh.
        let uuid = NSUUID().UUIDString
        let tempPath = NSTemporaryDirectory().stringByAppendingPathComponent(uuid)
        let script = "GIT_SSH_COMMAND='ssh -i \(path)' git ls-remote \(repoSSHUrl)\n"
        
        var error: NSError?
        let success = script.writeToFile(tempPath, atomically: true, encoding: NSUTF8StringEncoding, error: &error)
        
        //something like GIT_SSH_COMMAND='ssh -i /path/to/keys' git ls-remote git@github.com:owner/repo.git
        let r = Script.run("bash", arguments: [tempPath])
        
        //delete the temp script
        NSFileManager.defaultManager().removeItemAtPath(tempPath, error: nil)
        return r
    }
}