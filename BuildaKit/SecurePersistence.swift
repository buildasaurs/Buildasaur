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
        typealias Keychain = NSMutableDictionary
    #endif
    
    #if RELEASE
        static let Prefix = "com.honzadvorsky.buildasaur"
    #else
        static let Prefix = "com.honzadvorsky.buildasaur.debug"
    #endif
    
    private let keychain: Keychain
    private let safe: Safe
    
    private init(keychain: Keychain, safe: Safe = EREW()) {
        self.keychain = keychain
        self.safe = safe
    }

    static func xcodeServerPasswordKeychain() -> SecurePersistence {
        return self.keychain("\(Prefix).xcs.password")
    }
    
    static func sourceServerTokenKeychain() -> SecurePersistence {
        return self.keychain("\(Prefix).source_server.oauth_tokens")
    }
    
    static func sourceServerPassphraseKeychain() -> SecurePersistence {
        return self.keychain("\(Prefix).source_server.passphrase")
    }
    
    static private func keychain(service: String) -> SecurePersistence {
        #if TESTING
        let keychain = NSMutableDictionary()
        #else
        let keychain = Keychain(service: service)
        #endif
        return self.init(keychain: keychain)
    }
    
    func read(key: String) -> String? {
        var val: String?
        self.safe.read {
            #if TESTING
                val = self.keychain[key] as? String
            #else
                val = self.keychain[key]
            #endif
        }
        return val
    }
    
    func readAll() -> [(String, String)] {
        var all: [(String, String)] = []
        self.safe.read {
            #if TESTING
                let keychain = self.keychain
                all = keychain.allKeys.map { ($0 as! String, keychain[$0 as! String] as! String) }
            #else
                let keychain = self.keychain
                all = keychain.allKeys().map { ($0, keychain[$0]!) }
            #endif
        }
        return all
    }
    
    func writeIfNeeded(key: String, value: String?) {
        self.safe.write {
            self.updateIfNeeded(key, value: value)
        }
    }
    
    private func updateIfNeeded(key: String, value: String?) {
        #if TESTING
            let existing = self.keychain[key] as? String
        #else
            let existing = self.keychain[key]
        #endif
        if existing != value {
            self.keychain[key] = value
        }
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

