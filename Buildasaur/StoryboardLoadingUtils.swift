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
    
    //for presentable view controllers
    func presentableViewControllerWithStoryboardIdentifier<T: PresentableViewController>(storyboardIdentifier: String, uniqueIdentifier: String, delegate: PresentableViewControllerDelegate?) -> T {
        
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
        viewController.presentingDelegate = delegate
        return viewController as! T
    }
    
    func typedViewControllerWithStoryboardIdentifier<T: NSViewController>(storyboardIdentifier: String) -> T {
        let viewController = self.viewControllerWithStoryboardIdentifier(storyboardIdentifier)
        let typedViewController = viewController as! T
        return typedViewController
    }
    
    //for all other view controllers
    func viewControllerWithStoryboardIdentifier(storyboardIdentifier: String) -> NSViewController {
        guard let viewController = self.storyboard.instantiateControllerWithIdentifier(storyboardIdentifier) as? NSViewController else {
            fatalError("Failed to instantiate View Controller with identifier \(storyboardIdentifier)")
        }
        return viewController
    }
}

protocol StoryboardLoaderDelegate: class {
    
    func storyboardLoaderExistingViewControllerWithIdentifier(identifier: String) -> PresentableViewController?
}
