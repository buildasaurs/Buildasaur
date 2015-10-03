//
//  SyncerConfig.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaUtils

public typealias RefType = String

public struct Ref {
    static func new() -> RefType {
        return NSUUID().UUIDString
    }
}

public struct SyncerConfig {
    
    public let id: RefType
    public var preferredTemplateRef: RefType
    public var projectRef: RefType
    public var xcodeServerRef: RefType
    
    public var postStatusComments: Bool
    public var syncInterval: NSTimeInterval
    public var waitForLttm: Bool
    public var watchedBranchNames: [String]
    
    //creates a default syncer config
    public init() {
        self.id = Ref.new()
        self.preferredTemplateRef = ""
        self.projectRef = ""
        self.xcodeServerRef = ""
        self.postStatusComments = true
        self.syncInterval = 15
        self.waitForLttm = false
        self.watchedBranchNames = []
    }
}

private struct Keys {
    
    static let Id = "id"
    static let PreferredTemplateRef = "preferred_template_ref"
    static let ProjectRef = "project_ref"
    static let ServerRef = "server_ref"
    
    static let PostStatusComments = "post_status_comments"
    static let SyncInterval = "sync_interval"
    static let WaitForLttm = "wait_for_lttm"
    static let WatchedBranches = "watched_branches"
}

extension SyncerConfig: JSONSerializable {
    
    public func jsonify() -> NSDictionary {
        return [
            Keys.Id: self.id,
            Keys.PreferredTemplateRef: self.preferredTemplateRef,
            Keys.ProjectRef: self.projectRef,
            Keys.ServerRef: self.xcodeServerRef,
            Keys.PostStatusComments: self.postStatusComments,
            Keys.SyncInterval: self.syncInterval,
            Keys.WaitForLttm: self.waitForLttm,
            Keys.WatchedBranches: self.watchedBranchNames
        ]
    }
    
    public init(json: NSDictionary) throws {
        self.preferredTemplateRef = try json.get(Keys.PreferredTemplateRef)
        self.projectRef = try json.get(Keys.ProjectRef)
        self.xcodeServerRef = try json.get(Keys.ServerRef)
        self.postStatusComments = try json.get(Keys.PostStatusComments)
        self.syncInterval = try json.get(Keys.SyncInterval)
        self.waitForLttm = try json.get(Keys.WaitForLttm)
        self.watchedBranchNames = try json.get(Keys.WatchedBranches)
        self.id = try json.getOptionally(Keys.Id) ?? Ref.new()
    }
}
