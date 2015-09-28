//
//  SyncerViewModel.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 28/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import BuildaKit

struct SyncerViewModel {
    
    enum Column: String {
        case Status = "status"
        case XCSHost = "xcs_host"
        case ProjectName = "project_name"
        case BuildTemplate = "build_template"
        case Control = "control"
        case Edit = "edit"
    }

    let syncer: HDGitHubXCBotSyncer
    
    func objectForColumnIdentifier(columnIdentifier: String) -> AnyObject? {
        
        guard let column = Column(rawValue: columnIdentifier) else { return nil }
        return self.objectForColumn(column)
    }
    
    private func objectForColumn(column: Column) -> AnyObject? {
        
        switch column {
        case .Status:
            return "who knows?"
        case .XCSHost:
            let fullHost = self.syncer.xcodeServer.config.host
            let url = NSURL(string: fullHost)
            return url?.host
        case .ProjectName:
            return self.syncer.project.projectName
        case .BuildTemplate:
            return self.syncer.currentBuildTemplate().name
        case .Control:
            return "start/stop"
        case .Edit:
            return "Edit"
        }
    }
}

