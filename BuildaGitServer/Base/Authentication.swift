//
//  Authentication.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/26/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public struct ProjectAuthenticator {
    
    public enum AuthType: String {
        case PersonalToken
        case OAuthToken
    }
    
    public let service: GitService
    public let username: String
    public let type: AuthType
    public let secret: String
    
    public init(service: GitService, username: String, type: AuthType, secret: String) {
        self.service = service
        self.username = username
        self.type = type
        self.secret = secret
    }
}

public protocol KeychainStringSerializable {
    static func fromString(value: String) throws -> Self
    func toString() -> String
}

extension ProjectAuthenticator: KeychainStringSerializable {
    
    public static func fromString(value: String) throws -> ProjectAuthenticator {
        
        let comps = value.componentsSeparatedByString(":")
        guard comps.count >= 4 else { throw Error.withInfo("Corrupted keychain string") }

        var service: GitService
        switch comps[0] {
        case GitService.GitHub.hostname():
            service = GitService.GitHub
        case GitService.BitBucket.hostname():
            service = GitService.BitBucket
        default:
            let host = comps[0]
            guard let maybeService = GitService.createEnterpriseService(host) else {
                throw Error.withInfo("Unsupported service: \(host)")
            }
            service = maybeService
        }

        guard let type = ProjectAuthenticator.AuthType(rawValue: comps[2]) else {
            throw Error.withInfo("Unsupported auth type: \(comps[2])")
        }
        //join the rest back in case we have ":" in the token
        let remaining = comps.dropFirst(3).joinWithSeparator(":")
        let auth = ProjectAuthenticator(service: service, username: comps[1], type: type, secret: remaining)
        return auth
    }
    
    public func toString() -> String {
        
        return [
            self.service.hostname(),
            self.username,
            self.type.rawValue,
            self.secret
            ].joinWithSeparator(":")
    }
}
