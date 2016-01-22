//
//  SecurePersistence.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 1/22/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import Foundation
import KeychainAccess
import XcodeServerSDK

final class SecurePersistence {
    
    static let Prefix = "com.honzadvorsky.buildasaur"
    
    static func xcodeServerPasswordKeychain() -> Keychain {
        let keychain = Keychain(service: "\(Prefix).xcs.password")
        return keychain
    }
    
    static func sourceServerTokenKeychain() -> Keychain {
        let keychain = Keychain(service: "\(Prefix).source_server.oauth_tokens")
        return keychain
    }
    
    static func sourceServerPassphraseKeychain() -> Keychain {
        let keychain = Keychain(service: "\(Prefix).source_server.passphrase")
        return keychain
    }
}

public protocol KeychainSaveable {
    func keychainKey() -> String
}

extension XcodeServerConfig: KeychainSaveable {
    public func keychainKey() -> String {
        return "\(self.host):\(self.user ?? "")"
    }
}

extension ProjectConfig: KeychainSaveable {
    public func keychainKey() -> String {
        return self.id
    }
}

extension Keychain {
    
    func updateIfNeeded(key: String, value: String?) {
        if self[key] != value {
            self[key] = value
        }
    }
}

