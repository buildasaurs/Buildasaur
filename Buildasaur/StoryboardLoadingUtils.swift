//
//  StoryboardLoadingUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa

extension NSStoryboard {
    
    static var mainStoryboard: NSStoryboard {
        return NSStoryboard(name: "Main", bundle: nil)
    }
}

class StoryboardLoader {
    
    let storyboard: NSStoryboard
    weak var delegate: StoryboardLoaderDelegate?
    
    init(storyboard: NSStoryboard) {
        self.storyboard = storyboard
    }
    
    func viewControllerWithStoryboardIdentifier<T: PresentableViewController>(storyboardIdentifier: String, uniqueIdentifier: String) -> T {
        
        //look at our existing view controllers
        if let found = self.delegate?.storyboardLoaderExistingViewControllerWithIdentifier(uniqueIdentifier) {
            //we already have it live, let's reuse it
            return found as! T
        }
        
        //nope, we have to create it from storyboard
        guard let viewController = self.storyboard.instantiateControllerWithIdentifier(storyboardIdentifier) as? PresentableViewController else {
            fatalError("Failed to instantiate View Controller with identifier \(storyboardIdentifier) as a PresentableViewController")
        }
        
        //asign props
        viewController.uniqueIdentifier = uniqueIdentifier
        viewController.storyboardLoader = self
        return viewController as! T
    }
    
}

protocol StoryboardLoaderDelegate: class {
    
    func storyboardLoaderExistingViewControllerWithIdentifier(identifier: String) -> PresentableViewController?
}
