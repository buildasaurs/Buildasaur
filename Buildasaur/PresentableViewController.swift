//
//  PresentableViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 30/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa

class PresentableViewController: NSViewController {
    
    //so that when trying to present the view controller again we
    //first look whether it isn't already on screen.
    var uniqueIdentifier: String = ""
    
    //gives VC the ability to safely CREATE vcs without duplicates
    var storyboardLoader: StoryboardLoader!
    
    //gives VCs the ability to present more vcs in unique windows etc
    weak var presentingDelegate: PresentableViewControllerDelegate?
}

protocol PresentableViewControllerDelegate: class {
    
    func presentViewControllerInUniqueWindow(viewController: PresentableViewController)
}
