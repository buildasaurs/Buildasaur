//
//  BuildasaurUITests.swift
//  BuildasaurUITests
//
//  Created by Honza Dvorsky on 10/4/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import XCTest

class BuildasaurUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateNewServer() {
        
        let app = XCUIApplication()
        app.windows.elementBoundByIndex(0).buttons["New Syncer"].click()
        
        let buildasaurWindow = app.windows["Buildasaur"]
        buildasaurWindow.buttons["New Xcode Server..."].click()
        
        let xcodeServerHostnameTextField = buildasaurWindow.textFields["Xcode Server Hostname"]
        xcodeServerHostnameTextField.click()
        xcodeServerHostnameTextField.typeText("newhost\t")
        buildasaurWindow.textFields["Xcode Server User"].typeText("newuser\t")
        buildasaurWindow.buttons["go right"].click()
        buildasaurWindow.buttons["go left"].click()
        buildasaurWindow.childrenMatchingType(.PopUpButton).element.click()
        buildasaurWindow.click()
    }
    
}
