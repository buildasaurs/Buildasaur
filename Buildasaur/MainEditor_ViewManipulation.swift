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
    }

    func setContentViewController(viewController: EditableViewController) {
        
        self.removeContentViewController()
        self.addContentViewController(viewController)
    }
    
    private func removeContentViewController() {
        
        guard let content = self._contentViewController else { return }
        content.view.removeFromSuperview()
        content.removeFromParentViewController()
        self._contentViewController = nil
    }
    
    private func addContentViewController(viewController: EditableViewController) {

        precondition(self._contentViewController == nil)
        
        self.addChildViewController(viewController)
        let view = viewController.view
        self.containerView.addSubview(view)
        view.frame = self.containerView.bounds
        self._contentViewController = viewController
        self.rebindContentViewController()
    }
}
