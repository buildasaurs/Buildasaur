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
    func createSyncers(configs: [ConfigTriplet]) -> [HDGitHubXCBotSyncer]
    func defaultConfigTriplet() -> ConfigTriplet
    func newEditableTriplet() -> EditableConfigTriplet
    func createXcodeServer(config: XcodeServerConfig) -> XcodeServer
    func createProject(config: ProjectConfig) -> Project?
    func createSourceServer(token: String) -> SourceServerType
    func createTrigger(config: TriggerConfig) -> Trigger
}

public class SyncerFactory: SyncerFactoryType {
    
    private var syncerPool = [RefType: HDGitHubXCBotSyncer]()
    private var projectPool = [RefType: Project]()
    private var xcodeServerPool = [RefType: XcodeServer]()
    
    public init() { }
    
    private func createSyncer(triplet: ConfigTriplet) -> HDGitHubXCBotSyncer? {
        
        let xcodeServer = self.createXcodeServer(triplet.server)
        //TODO: pull out authentication as SourceServerOptions
        let sourceServer = self.createSourceServer(triplet.project.serverAuthentication ?? "")
        let maybeProject = self.createProject(triplet.project)
        let triggers = triplet.triggers.map { self.createTrigger($0) }
        
        guard let project = maybeProject else { return nil }
        
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
        
        let syncer = HDGitHubXCBotSyncer(
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
    
    public func createSyncers(configs: [ConfigTriplet]) -> [HDGitHubXCBotSyncer] {
        
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
    
    public func createSourceServer(token: String) -> SourceServerType {
        
        let options: Set<SourceServerOption> = [.Token(token)]
        let server: SourceServerType = SourceServerFactory().createServer(options)
        return server
    }
    
    public func createTrigger(config: TriggerConfig) -> Trigger {
        let trigger = Trigger(config: config)
        return trigger
    }
}
