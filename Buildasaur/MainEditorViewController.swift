//
//  MainEditorViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit
import ReactiveCocoa

protocol EditorViewControllerFactoryType {
    
    func supplyViewControllerForState(state: EditorState, context: EditorContext) -> EditableViewController
}

class MainEditorViewController: PresentableViewController {
    
    var factory: EditorViewControllerFactoryType!
    var context: EditorContext!
    
    @IBOutlet weak var containerView: NSView!
    
    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    
    var state = MutableProperty<EditorState>(.NoServer)

    var _contentViewController: EditableViewController?
        
    @IBAction func previousButtonClicked(sender: AnyObject) {
        //state machine - will say "Cancel" and dismiss if on first page,
        //otherwise will say "Previous" and move one back in the flow
        self.previous()
    }
    
    @IBAction func nextButtonClicked(sender: AnyObject) {
        //state machine - will say "Save" and dismiss if on the last page,
        //otherwise will say "Next" and move one forward in the flow
        self.next()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupBindings()
        
        self.containerView.wantsLayer = true
        self.containerView.layer!.backgroundColor = NSColor.grayColor().CGColor
    }
    
    // moving forward and back
    
    func previous() {
        
        if let previous = self.state.value.previous() {
            self.state.value = previous
        } else {
            //we're at the beginning, dismiss?
        }
    }
    
    func next() {
        
        if let next = self.state.value.next() {
            self.state.value = next
        } else {
            //we're at the end, dismiss?
        }
    }
    
    //setup RAC
    
    private func setupBindings() {
        
        self.state
            .producer
            .combinePrevious(.Initial) //keep history
            .filter { $0.0 != $0.1 } //only take changes
            .startWithNext { [weak self] in
                self?.stateChanged($0, toState: $1)
        }
    }
    
    //state manipulation
    
    private func stateChanged(fromState: EditorState, toState: EditorState) {
        
        if let content = self._contentViewController {
            //give the controller to be removed callbacks about previous/next
            precondition(fromState != toState)
            if fromState < toState {
                content.willGoNext()
            } else {
                content.willGoPrevious()
            }
        }

        let viewController = self.factory.supplyViewControllerForState(toState, context: self.context)
        self.setContentViewController(viewController)
    }
}

