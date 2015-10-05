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
import BuildaUtils

protocol EditorViewControllerFactoryType {
    
    func supplyViewControllerForState(state: EditorState, context: EditorContext) -> EditableViewController?
}

class MainEditorViewController: PresentableViewController {
    
    var factory: EditorViewControllerFactoryType!
    var context: EditorContext!
    
    @IBOutlet weak var containerView: NSView!
    
    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    
    //state and animated?
    var state = MutableProperty<(EditorState, Bool)>(.NoServer, false)

    var _contentViewController: EditableViewController?
        
    @IBAction func previousButtonClicked(sender: AnyObject) {
        //state machine - will say "Cancel" and dismiss if on first page,
        //otherwise will say "Previous" and move one back in the flow
        self.previous(animated: false)
    }
    
    @IBAction func nextButtonClicked(sender: AnyObject) {
        //state machine - will say "Save" and dismiss if on the last page,
        //otherwise will say "Next" and move one forward in the flow
        self.next(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.containerView.wantsLayer = true
        self.containerView.layer!.backgroundColor = NSColor.grayColor().CGColor

        self.setupBindings()
    }
    
    // moving forward and back
    
    func previous(animated animated: Bool) {
        
        //check with the current controller first
        if let content = self._contentViewController {
            if !content.shouldGoPrevious() {
                return
            }
        }
        
        self._previous(animated: animated)
    }
    
    //not verified that vc is okay with it
    func _previous(animated animated: Bool) {
        
        if let previous = self.state.value.0.previous() {
            self.state.value = (previous, animated)
        } else {
            //we're at the beginning, dismiss?
        }
    }
    
    func next(animated animated: Bool) {
        
        //check with the current controller first
        if let content = self._contentViewController {
            if !content.shouldGoNext() {
                return
            }
        }
        
        self._next(animated: animated)
    }
    
    func _next(animated animated: Bool) {
        
        if let next = self.state.value.0.next() {
            self.state.value = (next, animated)
        } else {
            //we're at the end, dismiss?
        }
    }
    
    //setup RAC
    
    private func setupBindings() {
        
        self.state
            .producer
            .combinePrevious((.Initial, false)) //keep history
            .filter { $0.0.0 != $0.1.0 } //only take changes
            .startWithNext { [weak self] in
                self?.stateChanged(fromState: $0.0, toState: $1.0, animated: $1.1)
        }
    }
    
    //state manipulation
    
    private func stateChanged(fromState fromState: EditorState, toState: EditorState, animated: Bool) {

        if let viewController = self.factory.supplyViewControllerForState(toState, context: self.context) {
            self.setContentViewController(viewController, animated: animated)
        } else {
            self.dismissWindow()
        }
    }
    
    private func dismissWindow() {
        self.presentingDelegate?.closeWindowWithViewController(self)
    }
}

