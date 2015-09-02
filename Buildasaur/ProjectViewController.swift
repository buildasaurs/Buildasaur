//
//  ProjectViewController.swift
//  Buildasaur
//
//  Created by David Cilia on 8/25/15.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit

//Private Keys
private let kSourceProjectKey = "Project"
private let kSourceRepositoryNameKey = "Repository Name"
private let kSourceURLKey = "URL"
private let kSourceWCCNameKey = "WCCName"
private let kCreateNewBuildasaurSegueIdentifier = "createNewBuildasaur"
private let kLaunchBuildasaurSegueIdentifier = "showBuildasaur"
private let kSelectorOpenProjectDetailsKey = "openProjectDetails:"
private let kSelectorControllerWillClose = "statusProjectControllerWillClose:"
private let kSelectorProjectsChanged = "projectsDidChange:"
private let kSelectorContextualMenu = "deleteProjectFromContextualMenu:"
//end Private Keys


class ProjectViewController: NSViewController, MinimumSuggestedWindowSizing {

    //Private variables have an underscore
    private var _selectedProject : Project?
    private var _multipleRowsSelected : Bool = false
    
    //When a window is opened for a specific project, it is added to the
    //collection, when closed it is removed.
    private var _activeProjectWindows = [String : ProjectDataSource]()
    
    @IBOutlet weak var tableView: NSTableView! {
        didSet {
           
            self.tableView.setDelegate(self)
            self.tableView.setDataSource(self)
        }
    }
    
    var projects : [Project] {
        
        return StorageManager.sharedInstance.projects
    }

//MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        //Double click on the row will open the 3 status screens controller
        self.tableView.doubleAction = NSSelectorFromString(kSelectorOpenProjectDetailsKey)
        self.registerObservers()
        self.setupContextualClick()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.setSuggestedMinimumWindowSize(self)
    }
    
    deinit {
        self.tearDownObservers()
    }
}


//MARK: Overrides
extension ProjectViewController {

    func setupContextualClick() -> Void {

        let menuItem = NSMenuItem(title: "Delete", action: NSSelectorFromString(kSelectorContextualMenu), keyEquivalent: "")
        let menu = NSMenu(title: "Options")
        menu.insertItem(menuItem, atIndex: 0)
        self.tableView.menu = menu
    }
}

//MARK: NSTableViewDataSource
extension ProjectViewController: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    
        return self.projects.count
    }
}

private let CellId = "ProjectCell"

//MARK: NSTableViewDelegate
extension ProjectViewController : NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let cell = tableView.makeViewWithIdentifier(CellId, owner: self) as? NSTableCellView {
            
            if let field = self.patternMatch(row, column: tableColumn!) {
                
                cell.textField?.stringValue = field
            }
            
            return cell
            
        }
        else {
            
            let cell = NSTableCellView(frame: CGRectZero)
            
            if let field = self.patternMatch(row, column: tableColumn!) {
                
                cell.textField?.stringValue = field
            }
            
            return cell
        }
    }
    
    func tableView(tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet) -> NSIndexSet {
        
        if proposedSelectionIndexes.count > 1 {
            
            _multipleRowsSelected = true
        }
        else {
            _multipleRowsSelected = false
        }
        
        if proposedSelectionIndexes.count > 0 {
            let row = proposedSelectionIndexes.firstIndex
            let project = self.projects[row]
            _selectedProject = project
        }
        else {
            //Nothing is selected, so clear out the selected project
            //variable
            _selectedProject = nil
        }
    
        return proposedSelectionIndexes
    }
}

//MARK: Segues
extension ProjectViewController {
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        let id = identifier
        
        if self._selectedProject != nil && id == kLaunchBuildasaurSegueIdentifier {
            if self.activeWindowsContainsProject(self._selectedProject!) == true {
                return false
            }
        }
        
        if self._selectedProject == nil && id != kCreateNewBuildasaurSegueIdentifier {
            
            return false
        }
        
        return true
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        if let id = segue.identifier {
            
            switch id {
                
            case kCreateNewBuildasaurSegueIdentifier:
                
                self.tableView.deselectAll(nil)
                break
            case kLaunchBuildasaurSegueIdentifier:
                
                if let selected = self._selectedProject {
                    if self.activeWindowsContainsProject(selected) == true {
                        return
                    }
                    if var destination = segue.destinationController as? ProjectDataSource {
                        
                        destination.dataSource = self
                        self.addController(destination, activeProject:selected)
                    }
                }
                
            default:
                break
            }
        }
    }
}

//MARK: ProjectDataSource Implementation
extension ProjectViewController: ProjectDataSource {
    
    //This controller does not have a datasource.
    var dataSource : ProjectDataSource? {
        get {
            return nil
        }
        set {
            self.dataSource = nil
        }
    }
    
    var project : Project? {
        return self._selectedProject
    }
}


//MARK: Multiple Window Tracking
extension ProjectViewController {
    
    func addController(controller: ProjectDataSource, activeProject: Project) -> Void {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: NSSelectorFromString(kSelectorControllerWillClose), name: NSWindowWillCloseNotification, object: nil)
        self._activeProjectWindows[activeProject.url.absoluteString] = controller
    }
    
    func removeController(controller: ProjectDataSource, activeProject: Project) -> Void {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSWindowWillCloseNotification, object: nil)
        self._activeProjectWindows[activeProject.url.absoluteString] = nil
    }
    
    func statusProjectControllerWillClose(notif: NSNotification) -> Void {
        
        let window = notif.object as! NSWindow
        
        if let me = window.contentViewController as? ProjectDataSource {
            if let item = me.dataSource?.project {
                self.removeController(me, activeProject: item)
            }
        }
    }
    
    func activeWindowsContainsProject(activeProject: Project) -> Bool {
        
        if self._activeProjectWindows[activeProject.url.absoluteString] != nil {
                return true
        }
        
        return false
    }
}


//MARK: Helpers
extension ProjectViewController {
    
    func patternMatch(row : Int, column: NSTableColumn) -> String? {
        
        let project = self.projects[row]
        
        switch column.identifier {
            
        case kSourceProjectKey:
            return project.projectName
        case kSourceRepositoryNameKey:
            return project.githubRepoName()
        case kSourceURLKey:
            return project.projectURL?.absoluteString
        case kSourceWCCNameKey:
            return project.projectWCCName
        default:
            return nil
        }
    }
    
    func openProjectDetails(sender: AnyObject) -> Void {
        
        self.performSegueWithIdentifier(kLaunchBuildasaurSegueIdentifier, sender: self)
    }
    
    func deleteProjectFromContextualMenu(sender: AnyObject) -> Void {
        
        let manager = StorageManager.sharedInstance
        let clickedProject = manager.projects[self.tableView.clickedRow]
        manager.removeProject(clickedProject)
        manager.saveProjects()
        self.tableView.reloadData()
    }
}

//MARK: KVO

extension ProjectViewController {
    
    func registerObservers() -> Void {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: NSSelectorFromString(kSelectorProjectsChanged), name: ProjectsDidChangeNotification, object: StorageManager.sharedInstance)
        
    }
    
    func tearDownObservers() -> Void {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ProjectsDidChangeNotification, object: StorageManager.sharedInstance)
        
    }
    
    func projectsDidChange(sender: AnyObject) {
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.tableView.reloadData()
        }
    }
}

//MARK: Project DataSource

/**
Controller asks the data source for
the project it should display.
*/
protocol ProjectDataSource {
    
    var dataSource : ProjectDataSource? { get set }
    var project : Project? { get }
}

extension ProjectDataSource {
    
    var project: Project? {
        get {
            return nil
        }
    }
}

//MARK: Minimum Window Resizing

protocol MinimumSuggestedWindowSizing {
    
    func setSuggestedMinimumWindowSize(viewController: NSViewController) -> Void
}

extension  MinimumSuggestedWindowSizing {
    
    func setSuggestedMinimumWindowSize(viewController: NSViewController) -> Void {
        
        if let window = viewController.view.window {
            window.minSize = CGSizeMake(658, 512)
            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            window.title = "Buildasaur \(version), at your service"
        }
    }
}
