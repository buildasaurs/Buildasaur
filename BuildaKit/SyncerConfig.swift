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

    public let preferredTemplateRef: RefType
    public let projectRef: RefType
    public let xcodeServerRef: RefType
    
    public let postStatusComments: Bool
    public let syncInterval: NSTimeInterval
    public let waitForLttm: Bool
    public let watchedBranchNames: [String]
    
    public init(preferredTemplateRef: RefType, projectRef: RefType, xcodeServerRef: RefType, postStatusComments: Bool, syncInterval: NSTimeInterval, waitForLttm: Bool, watchedBranchNames: [String]) {
        self.preferredTemplateRef = preferredTemplateRef
        self.projectRef = projectRef
        self.xcodeServerRef = xcodeServerRef
        self.postStatusComments = postStatusComments
        self.syncInterval = syncInterval
        self.waitForLttm = waitForLttm
        self.watchedBranchNames = watchedBranchNames
    }
}

private struct Keys {
    
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
    }
}
