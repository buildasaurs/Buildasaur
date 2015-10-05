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
        content.wantsNext.observeNext { [weak self] in self?._next(animated: $0) }
        content.wantsPrevious.observeNext { [weak self] in self?._previous(animated: false) }
    }
    
    private func remove(viewController: NSViewController?) {
        guard let vc = viewController else { return }
        vc.view.removeFromSuperview()
        vc.removeFromParentViewController()
    }
    
    private func add(viewController: EditableViewController, offsetMultiplier: Double) {
        self.addChildViewController(viewController)
        let view = viewController.view
        self.containerView.addSubview(view)
        
        var frame = self.containerView.bounds
        frame.origin.x += (CGFloat(offsetMultiplier) * frame.size.width)
        view.frame = frame
        
        //also match backgrounds?
        view.wantsLayer = true
        view.layer!.backgroundColor = self.containerView.layer!.backgroundColor
        
        //setup
        self._contentViewController = viewController
        self.rebindContentViewController()
    }
    
    func setContentViewController(viewController: EditableViewController, animated: Bool) {
        
        let oldViewController: NSViewController? = self._contentViewController
        let completion = {
            self.remove(oldViewController)
        }
        
        //add the new one immediately
        let offsetMultiplier = animated ? 1.0 : 0.0
        self.add(viewController, offsetMultiplier: offsetMultiplier)
        
        //if no animation, complete immediately
        if !animated {
            completion()
            return
        }
        
        //animation, yay!
        
        //1. move the new controller out of screen on the right
        let originalFrame = self.containerView.bounds
        
        //2. start an animation from right to the center
        NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) -> Void in
            
            context.duration = 1
            viewController.view.animator().frame = originalFrame
            
            }) { () -> Void in
                
                //3. completion, remove the old view
                completion()
        }
    }
}
