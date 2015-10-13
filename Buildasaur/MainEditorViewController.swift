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
    let context = MutableProperty<EditorContext>(EditorContext())
    
    @IBOutlet weak var containerView: NSView!
    
    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    
    //state and animated?
    let state = MutableProperty<(EditorState, Bool)>(.NoServer, false)

    var _contentViewController: EditableViewController?
    
    @IBAction func previousButtonClicked(sender: AnyObject) {
        //state machine - will be disabled on the first page,
        //otherwise will say "Previous" and move one back in the flow
        self.previous(animated: false)
    }
    
    @IBAction func nextButtonClicked(sender: AnyObject) {
        //state machine - will say "Save" and dismiss if on the last page,
        //otherwise will say "Next" and move one forward in the flow
        self.next(animated: true)
    }
    
    @IBAction func cancelButtonClicked(sender: AnyObject) {
        //just a cancel button.
        self.cancel()
    }
    
    func loadInState(state: EditorState) {
        self.state.value = (state, false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.containerView.wantsLayer = true
        self.containerView.layer!.backgroundColor = NSColor.lightGrayColor().CGColor

        self.setupBindings()
        
        //HACK: hack for debugging - jump ahead
//        self.state.value = (.EditingSyncer, false)
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
    
    func cancel() {
        
        //check with the current controller first
        if let content = self._contentViewController {
            if !content.shouldCancel() {
                return
            }
        }
        
        self._cancel()
    }
    
    func _cancel() {
        
        self.dismissWindow()
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
        
        self.state.producer.map { $0.0 == .NoServer }.startWithNext { [weak self] in
            if $0 {
                self?.previousButton.enabled = false
            }
        }
        
        //create a title
        self.context.producer.map { context -> String in
            let triplet = context.configTriplet
            var comps = [String]()
            if let host = triplet.server?.host {
                comps.append(host)
            } else {
                comps.append("New Server")
            }
            if let projectName = triplet.project?.name {
                comps.append(projectName)
            } else {
                comps.append("New Project")
            }
            if let templateName = triplet.buildTemplate?.name {
                comps.append(templateName)
            } else {
                comps.append("New Build Template")
            }
            return comps.joinWithSeparator(" + ")
        }.startWithNext { [weak self] in
            self?.title = $0
        }
    }
    
    //state manipulation
    
    private func stateChanged(fromState fromState: EditorState, toState: EditorState, animated: Bool) {

        let context = self.context.value
        if let viewController = self.factory.supplyViewControllerForState(toState, context: context) {
            self.setContentViewController(viewController, animated: animated)
        } else {
            self.dismissWindow()
        }
    }
    
    internal func dismissWindow() {
        self.presentingDelegate?.closeWindowWithViewController(self)
    }
}

