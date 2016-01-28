//
//  SyncerFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer

public protocol SyncerFactoryType {
    func createSyncers(configs: [ConfigTriplet]) -> [StandardSyncer]
    func defaultConfigTriplet() -> ConfigTriplet
    func newEditableTriplet() -> EditableConfigTriplet
    func createXcodeServer(config: XcodeServerConfig) -> XcodeServer
    func createProject(config: ProjectConfig) -> Project?
    func createSourceServer(service: GitService, auth: ProjectAuthenticator?) -> SourceServerType
    func createTrigger(config: TriggerConfig) -> Trigger
}

public protocol SyncerLifetimeChangeObserver {
    func authChanged(projectConfigId: String, auth: ProjectAuthenticator)
}

public class SyncerFactory: SyncerFactoryType {
    
    private var syncerPool = [RefType: StandardSyncer]()
    private var projectPool = [RefType: Project]()
    private var xcodeServerPool = [RefType: XcodeServer]()
    
    public var syncerLifetimeChangeObserver: SyncerLifetimeChangeObserver!
    
    public init() { }
    
    private func createSyncer(triplet: ConfigTriplet) -> StandardSyncer? {
        
        precondition(self.syncerLifetimeChangeObserver != nil)
        
        let xcodeServer = self.createXcodeServer(triplet.server)
        let maybeProject = self.createProject(triplet.project)
        let triggers = triplet.triggers.map { self.createTrigger($0) }
        
        guard let project = maybeProject else { return nil }
        
        guard let service = project.workspaceMetadata?.service else { return nil }
        
        let projectConfig = triplet.project
        let sourceServer = self.createSourceServer(service, auth: projectConfig.serverAuthentication)
        sourceServer
            .authChangedSignal()
            .ignoreNil()
            .observeNext { [weak self] (auth) -> () in
                self?
                    .syncerLifetimeChangeObserver
                    .authChanged(projectConfig.id, auth: auth)
        }
        
        if let poolAttempt = self.syncerPool[triplet.syncer.id]
        {
            poolAttempt.config.value = triplet.syncer
            poolAttempt.xcodeServer = xcodeServer
            poolAttempt.sourceServer = sourceServer
            poolAttempt.project = project
            poolAttempt.buildTemplate = triplet.buildTemplate
            poolAttempt.triggers = triggers
            return poolAttempt
        }
        
        let syncer = StandardSyncer(
            integrationServer: xcodeServer,
            sourceServer: sourceServer,
            project: project,
            buildTemplate: triplet.buildTemplate,
            triggers: triggers,
            config: triplet.syncer)
        
        self.syncerPool[triplet.syncer.id] = syncer
        
        //TADAAA
        return syncer
    }
    
    public func createSyncers(configs: [ConfigTriplet]) -> [StandardSyncer] {
        
        //create syncers
        let created = configs.map { self.createSyncer($0) }.filter { $0 != nil }.map { $0! }
        
        let createdIds = Set(created.map { $0.config.value.id })
        
        //remove the syncers that haven't been created (deleted)
        let deleted = Set(self.syncerPool.keys).subtract(createdIds)
        deleted.forEach {
            self.syncerPool[$0]?.active = false
            self.syncerPool.removeValueForKey($0)
        }
        
        return created
    }
    
    public func defaultConfigTriplet() -> ConfigTriplet {
        return ConfigTriplet(syncer: SyncerConfig(), server: XcodeServerConfig(), project: ProjectConfig(), buildTemplate: BuildTemplate(), triggers: [])
    }
    
    public func newEditableTriplet() -> EditableConfigTriplet {
        return EditableConfigTriplet(syncer: SyncerConfig(), server: nil, project: nil, buildTemplate: nil, triggers: nil)
    }
    
    //sort of private
    public func createXcodeServer(config: XcodeServerConfig) -> XcodeServer {
        
        if let poolAttempt = self.xcodeServerPool[config.id] {
            poolAttempt.config = config
            return poolAttempt
        }

        let server = XcodeServerFactory.server(config)
        self.xcodeServerPool[config.id] = server
        
        return server
    }
    
    public func createProject(config: ProjectConfig) -> Project? {
        
        if let poolAttempt = self.projectPool[config.id] {
            poolAttempt.config.value = config
            return poolAttempt
        }
        
        //TODO: maybe this producer SHOULD throw errors, when parsing fails?
        let project = try? Project(config: config)
        if let project = project {
            self.projectPool[config.id] = project
        }
        
        return project
    }
    
    public func createSourceServer(service: GitService, auth: ProjectAuthenticator?) -> SourceServerType {
        
        let server = SourceServerFactory().createServer(service, auth: auth)
        return server
    }
    
    public func createTrigger(config: TriggerConfig) -> Trigger {
        let trigger = Trigger(config: config)
        return trigger
    }
}
