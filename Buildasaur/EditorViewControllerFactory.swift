//
//  EditorViewControllerFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import XcodeServerSDK

enum EditorVCType: String {
    case XcodeServerVC = "xcodeServerViewController"
    case EmptyXcodeServerVC = "emptyXcodeServerViewController"
    case ProjectVC = "projectViewController"
    case EmptyProjectVC = "emptyProjectViewController"
    case BuildTemplateVC = "buildTemplateViewController"
    case EmptyBuildTemplateVC = "emptyBuildTemplateViewController"
    case SyncerStatusVC = "syncerViewController"
}

class EditorViewControllerFactory: EditorViewControllerFactoryType {
    
    let storyboardLoader: StoryboardLoader
    
    init(storyboardLoader: StoryboardLoader) {
        self.storyboardLoader = storyboardLoader
    }
    
    func supplyViewControllerForState(state: EditorState, context: EditorContext) -> EditableViewController? {
        
        switch state {
            
        case .Initial, .Final:
            return nil
            
        case .NoServer:
            let vc: EmptyXcodeServerViewController = self.storyboardLoader.typedViewControllerWithStoryboardIdentifier(EditorVCType.EmptyXcodeServerVC.rawValue)
            if let serverConfig = context.configTriplet.server {
                vc.existingConfigId = serverConfig.id
            }
            vc.syncerManager = context.syncerManager
            vc.emptyServerDelegate = context.editeeDelegate
            return vc
            
        case .EditingServer:
            let vc: XcodeServerViewController = self.storyboardLoader.typedViewControllerWithStoryboardIdentifier(EditorVCType.XcodeServerVC.rawValue)
            vc.serverConfig.value = context.configTriplet.server!
            vc.syncerManager = context.syncerManager
            vc.cancelDelegate = context.editeeDelegate
            return vc
            
        case .NoProject:
            let vc: EmptyProjectViewController = self.storyboardLoader.typedViewControllerWithStoryboardIdentifier(EditorVCType.EmptyProjectVC.rawValue)
            vc.syncerManager = context.syncerManager
            vc.emptyProjectDelegate = context.editeeDelegate
            return vc
            
        case .EditingProject:
            let vc: ProjectViewController = self.storyboardLoader.typedViewControllerWithStoryboardIdentifier(EditorVCType.ProjectVC.rawValue)
            vc.projectConfig.value = context.configTriplet.project!
            vc.syncerManager = context.syncerManager
            vc.cancelDelegate = context.editeeDelegate
            return vc
        
        case .NoBuildTemplate:
            let vc: EmptyBuildTemplateViewController = self.storyboardLoader.typedViewControllerWithStoryboardIdentifier(EditorVCType.EmptyBuildTemplateVC.rawValue)
            vc.projectName = context.configTriplet.project!.name
            vc.existingTemplateId = context.configTriplet.buildTemplate?.id
            vc.syncerManager = context.syncerManager
            vc.emptyTemplateDelegate = context.editeeDelegate
            return vc
            
        case .EditingBuildTemplate:
            let vc: BuildTemplateViewController = self.storyboardLoader.typedViewControllerWithStoryboardIdentifier(EditorVCType.BuildTemplateVC.rawValue)
            vc.buildTemplate.value = context.configTriplet.buildTemplate!
            vc.projectRef = context.configTriplet.project!.id
            vc.xcodeServerRef = context.configTriplet.server!.id
            vc.syncerManager = context.syncerManager
            vc.cancelDelegate = context.editeeDelegate
            return vc
            
        default: break
        }
        fatalError("No controller for state \(state)")
    }
}
