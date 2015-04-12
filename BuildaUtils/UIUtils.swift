//
//  UIUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 07/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import AppKit

public enum AvailabilityCheckState {
    case Unchecked
    case Checking
    case Failed(NSError?)
    case Succeeded
}

public class UIUtils {
    
    public class func showAlertWithError(error: NSError) {
        
        let alert = self.createErrorAlert(error)
        self.presentAlert(alert, completion: { (resp) -> () in
            //
        })
    }
    
    public class func showAlertAskingForRemoval(text: String, completion: (remove: Bool) -> ()) {
        
        let removeText = "Remove"
        let buttons = ["Cancel", removeText]
        self.showAlertWithButtons(text, buttons: buttons) { (tappedButton) -> () in
            completion(remove: removeText == tappedButton)
        }
    }
    
    public class func showAlertWithButtons(text: String, buttons: [String], completion: (tappedButton: String) -> ()) {
        
        let alert = self.createAlert(text, style: nil)
        
        buttons.map { alert.addButtonWithTitle($0) }
        
        self.presentAlert(alert, completion: { (resp) -> () in
            
            //some magic where indices are starting at 1000... so subtract 1000 to get the array index of tapped button
            let idx = resp - NSAlertFirstButtonReturn
            let buttonText = buttons[idx]
            completion(tappedButton: buttonText)
        })
    }
    
    public class func showAlertWithText(text: String, style: NSAlertStyle? = nil, completion: ((NSModalResponse) -> ())? = nil) {

        let alert = self.createAlert(text, style: style)
        self.presentAlert(alert, completion: completion)
    }
    
    private class func createErrorAlert(error: NSError) -> NSAlert {
        return NSAlert(error: error)
    }
    
    private class func createAlert(text: String, style: NSAlertStyle?) -> NSAlert {
        
        var alert = NSAlert()
        
        alert.alertStyle = style ?? .InformationalAlertStyle
        alert.messageText = text
        
        return alert
    }
    
    private class func presentAlert(alert: NSAlert, completion: ((NSModalResponse) -> ())?) {
        
        if let window = NSApp.windows.first as? NSWindow {
            let resp = alert.runModal()
            completion?(resp)
//            alert.beginSheetModalForWindow(window, completionHandler: completion)
        } else {
            //no window to present in, at least print
            Log.info("Alert: \(alert.messageText)")
        }
    }
}
