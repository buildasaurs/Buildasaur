//
//  XcodeDeviceParser.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/06/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK

public class XcodeDeviceParser {
    
    public enum DeviceType: String {
        case iPhoneOS = "iphoneos"
        case macOSX = "macosx"
        case watchOS = "watchos"
    }
    
    public class func parseDeviceTypeFromProjectUrlAndScheme(projectUrl: NSURL, scheme: String) throws -> DeviceType {
        
        let typeString = try self.parseTargetTypeFromSchemeAndProjectAtUrl(scheme, projectFolderUrl: projectUrl)
        guard let deviceType = DeviceType(rawValue: typeString) else {
            throw Error.withInfo("Unrecognized type: \(typeString)")
        }
        return deviceType
    }
    
    private class func parseTargetTypeFromSchemeAndProjectAtUrl(schemeName: String, projectFolderUrl: NSURL) throws -> String {
        
        let folder = projectFolderUrl.URLByDeletingLastPathComponent?.path ?? "~"
        let script = "cd \"\(folder)\"; xcodebuild -scheme \"\(schemeName)\" -showBuildSettings 2>/dev/null | egrep '^\\s*PLATFORM_NAME' | cut -d = -f 2 | uniq | xargs echo"
        let res = Script.runTemporaryScript(script)
        if res.terminationStatus == 0 {
            let deviceType = res.standardOutput.stripTrailingNewline()
            return deviceType
        }
        throw Error.withInfo("Termination status: \(res.terminationStatus), output: \(res.standardOutput), error: \(res.standardError)")
    }
}