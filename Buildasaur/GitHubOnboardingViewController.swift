//
//  GitHubOnboardingViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 06/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaGitServer
import hit

class GitHubOnboardingViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    
    @IBOutlet weak var tokenTextField: NSSecureTextField!
    @IBOutlet weak var reloadButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchBar: NSTextField!
    @IBOutlet weak var nextButton: NSButton!

    private var server: GitHubServer?
    private var repos = [Repo]()
    private var filteredRepos = [Repo]()
    private var trie: Trie?
    private var repoMapFromNames: [String: Repo]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.delegate = self
        self.tableView.setDataSource(self)
        self.tableView.setDelegate(self)
        
        self.progress(false)
    }
    
    func progress(on: Bool) {
        self.reloadButton.enabled = !on
        self.progressIndicator.hidden = !on
        if on {
            self.progressIndicator.startAnimation(nil)
        } else {
            self.progressIndicator.stopAnimation(nil)
        }
    }
    
    @IBAction func reloadButtonClicked(sender: AnyObject) {
        
        let token = self.tokenTextField.stringValue
        let server = GitHubFactory.server(token)
        self.server = server
        
        self.progress(true)
        
        server.getUserRepos { (repos, error) -> () in
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in

                self.progress(false)
                if let error = error {
                    UIUtils.showAlertWithError(error)
                    return
                }
                self.reposUpdated(repos)
            })
        }
    }
    
    @IBAction func nextButtonTapped(sender: AnyObject) {
        
    }
    
    func reposUpdated(repos: [Repo]?) {
        self.repos = repos ?? []
        self.filteredRepos = self.repos
        self.repoMapFromNames = self.repos.mapify({ $0.name })
        self.trie = Trie(strings: Array(self.repoMapFromNames!.keys))
        self.tableView.reloadData()
    }
    
    //MARK: search field delegate
    override func controlTextDidChange(obj: NSNotification) {
        
        //filter repos -> filteredRepos
        guard let trie = self.trie else {
            return
        }
        
        let searchString = self.searchBar.stringValue
        if searchString.characters.count > 0 {
            let matches = Set(trie.stringsMatchingPrefix(searchString))
            let matchedRepos = self.repos.filter({ matches.contains($0.name.lowercaseString) })
            self.filteredRepos = matchedRepos
        } else {
            self.filteredRepos = self.repos
        }
        
        //refresh table view
        self.tableView.reloadData()
    }
    
    func updateNextButton() {
        self.nextButton.enabled = self.filteredRepos.count > 0 && self.tableView.selectedRow >= 0
    }
    
    //MARK: table view stuff
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.filteredRepos.count ?? 0
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return self.filteredRepos[row].fullName
    }
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        self.updateNextButton()
        return true
    }
    
    //did select? double clicked? or just select and button to select?
//    tableView
}

extension Array {
    
    func mapify<U: Hashable>(block: (Element) -> (U)) -> [U: Element] {
        var dict = [U: Element]()
        for item in self {
            dict[block(item)] = item
        }
        return dict
    }
}







