//
//  ConfigTriplet.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/10/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK

//TODO: remove invalid configs on startup?

public struct ConfigTriplet {
    public var syncer: SyncerConfig
    public var server: XcodeServerConfig
    public var project: ProjectConfig
    public var buildTemplate: BuildTemplate
    public var triggers: [TriggerConfig]
    
    init(syncer: SyncerConfig, server: XcodeServerConfig, project: ProjectConfig, buildTemplate: BuildTemplate, triggers: [TriggerConfig]) {
        self.syncer = syncer
        self.server = server
        self.project = project
        self.buildTemplate = buildTemplate
        self.syncer.preferredTemplateRef = buildTemplate.id
        self.triggers = triggers
    }
    
    public func toEditable() -> EditableConfigTriplet {
        return EditableConfigTriplet(syncer: self.syncer, server: self.server, project: self.project, buildTemplate: self.buildTemplate, triggers: self.triggers)
    }
}

public struct EditableConfigTriplet {
    public var syncer: SyncerConfig
    public var server: XcodeServerConfig?
    public var project: ProjectConfig?
    public var buildTemplate: BuildTemplate?
    public var triggers: [TriggerConfig]?
    
    public func toFinal() -> ConfigTriplet {
        var syncer = self.syncer
        syncer.preferredTemplateRef = self.buildTemplate!.id
        return ConfigTriplet(syncer: syncer, server: self.server!, project: self.project!, buildTemplate: self.buildTemplate!, triggers: self.triggers!)
    }
}
