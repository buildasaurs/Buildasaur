//
//  ViewControllerFactory.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/3/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa

enum SyncerEditVCType: String {
    case XcodeServerVC = "xcodeServerViewController"
    case EmptyXcodeServerVC = "emptyXcodeServerViewController"
    case ProjectViewController = "projectViewController"
    case EmptyProjectViewController = "emptyProjectViewController"
    case SyncerStatusViewController = "syncerStatusViewController"
}

class ViewControllerFactory {
    
    let storyboardLoader: StoryboardLoader
    
    init(storyboardLoader: StoryboardLoader) {
        self.storyboardLoader = storyboardLoader
    }
    
    func createViewController<T: NSViewController>(type: SyncerEditVCType) -> T {
        let identifier = type.rawValue
        let viewController: T = self.storyboardLoader.typedViewControllerWithStoryboardIdentifier(identifier)
        return viewController
    }
}
