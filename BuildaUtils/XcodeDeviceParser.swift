//
//  XcodeDeviceParser.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/06/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation

public class XcodeDeviceParser {
    
    public enum DeviceType: String {
        case iPhoneOS = "iphoneos"
        case macOSX = "macosx"
        case watchOS = "???" //TODO:find out what the code is for watch apps
    }
    
    class func parseDeviceTypeFromProjectUrlAndScheme(projectUrl: NSURL, scheme: String) throws -> DeviceType {
        let url = NSURL(string: "/Users/honzadvorsky/Documents/Buildasaur/")!
        let scheme = "Buildasaur"
        try! self.parseTargetTypeFromSchemeAndProjectAtUrl(scheme, projectFolderUrl: url)
    }
    
    public class func parseTargetTypeFromSchemeAndProjectAtUrl(schemeName: String, projectFolderUrl: NSURL) throws -> String {
        
        let script = "cd \"\(projectFolderUrl)\"; xcodebuild -scheme \(schemeName) -showBuildSettings 2>/dev/null | egrep '^\\s*PLATFORM_NAME' | cut -d = -f 2 | uniq | xargs echo"
        let res = Script.runTemporaryScript(script)
        if res.terminationStatus == 0 {
            let deviceType = res.standardOutput.stripTrailingNewline()
            print("\(deviceType)")
        }
        return ""
    }
    
}