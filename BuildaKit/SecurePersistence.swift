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
import SwiftSafe

final class SecurePersistence {
    
    #if TESTING
        static let Prefix = "com.honzadvorsky.buildasaur.testing"
    #else
        static let Prefix = "com.honzadvorsky.buildasaur"
    #endif
    
    static func xcodeServerPasswordKeychain() -> SecurePersistence {
        let keychain = Keychain(service: "\(Prefix).xcs.password")
        return self.init(keychain: keychain)
    }
    
    static func sourceServerTokenKeychain() -> SecurePersistence {
        let keychain = Keychain(service: "\(Prefix).source_server.oauth_tokens")
        return self.init(keychain: keychain)
    }
    
    static func sourceServerPassphraseKeychain() -> SecurePersistence {
        let keychain = Keychain(service: "\(Prefix).source_server.passphrase")
        return self.init(keychain: keychain)
    }
    
    private let keychain: Keychain
    private let safe: Safe
    
    private init(keychain: Keychain, safe: Safe = CREW()) {
        self.keychain = keychain
        self.safe = safe
    }
    
    func read(key: String) -> String? {
        var val: String?
        self.safe.read {
            val = self.keychain[key]
        }
        return val
    }
    
    func writeIfNeeded(key: String, value: String?) {
        self.safe.write {
            self.updateIfNeeded(key, value: value)
        }
    }
    
    private func updateIfNeeded(key: String, value: String?) {
        if self.keychain[key] != value {
            self.keychain[key] = value
        }
    }
    
    #if TESTING
    func wipe() {
        self.safe.write {
            _ = try? self.keychain.removeAll()
        }
    }
    #endif
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

