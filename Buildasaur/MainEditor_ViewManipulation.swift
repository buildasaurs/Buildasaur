//
//  MainEditor_ViewManipulation.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 10/5/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import ReactiveCocoa

extension MainEditorViewController {
    
    //view controller manipulation

    private func rebindContentViewController() {
        
        let content = self._contentViewController!
        
        self.nextButton.rac_enabled <~ content.nextAllowed
        self.previousButton.rac_enabled <~ content.previousAllowed
        self.cancelButton.rac_enabled <~ content.cancelAllowed
        content.wantsNext.observeNext { [weak self] in self?._next(animated: $0) }
        content.wantsPrevious.observeNext { [weak self] in self?._previous(animated: false) }
        self.nextButton.rac_title <~ content.nextTitle
    }
    
    private func remove(viewController: NSViewController?) {
        guard let vc = viewController else { return }
        vc.view.removeFromSuperview()
        vc.removeFromParentViewController()
    }
    
    private func add(viewController: EditableViewController) {
        self.addChildViewController(viewController)
        let view = viewController.view
        self.containerView.addSubview(view)
        
        //also match backgrounds?
        view.wantsLayer = true
        view.layer!.backgroundColor = self.containerView.layer!.backgroundColor
        
        //setup
        self._contentViewController = viewController
        self.rebindContentViewController()
    }
    
    func setContentViewController(viewController: EditableViewController, animated: Bool) {
        
        //1. remove the old view
        self.remove(self._contentViewController)
        
        //2. add the new view on top of the old one
        self.add(viewController)
        
        //if no animation, complete immediately
        if !animated {
            return
        }
        
        //animation, yay!
        
        let newView = viewController.view
        
        //3. offset the new view to the right
        var startingFrame = newView.frame
        let originalFrame = startingFrame
        startingFrame.origin.x += startingFrame.size.width
        newView.frame = startingFrame
        
        //4. start an animation from right to the center
        NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) -> Void in
            
            context.duration = 0.3
            newView.animator().frame = originalFrame
            
            }) { /* do nothing */ }
    }
}
