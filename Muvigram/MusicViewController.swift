//
//  MusicViewController.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 11. 30..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import MediaPlayer
import RxSwift
import RxCocoa

final class MusicViewController: UITableViewController {
    
    fileprivate var resultSerchController = UISearchController()
    fileprivate var searchActive: Bool = false
    // @inject
    public var presenter: MusicPresenter<MusicViewController>!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Load music item list
        presenter.loadMusics()
        // Search bar settings
        viewInitialization()
        // Observer registration
        addObserver()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.getMusicCountWithShouldshow(resultSerchActive: resultSerchController.isActive)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return presenter.bindMusicItemCellWithShouldshow(resultSerchActive: resultSerchController.isActive,
                                                         cellForRowAt: indexPath,
                                                         dequeueReusableCellFunction: tableView.dequeueReusableCell)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        postObserver(cell: tableView.cellForRow(at: indexPath) as! MusicTableViewCell)
    }
    
    // Item height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    private func addObserver() {
        // Called from Main Page View Controller when moved to Camera Controller
        NotificationCenter.default.addObserver(self, selector: #selector(self.closeSearchBarWindow), name: NSNotification.Name(rawValue: "swipToCameraPage"), object: nil)
    }
    
    private func postObserver(cell: MusicTableViewCell) {
        // Passes the selected music item to the CameraviewController.
        NotificationCenter.default.post(name: NSNotification.Name("receiverMusicSelelted"), object: nil, userInfo: ["MPMediaItem": cell.mpMediaItem!])
        // Call the scrollToNext of MainPageViweController to switch the screen to CameraViewController.
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "goToCameraPage"), object: nil)
        //Close searchBar window
        closeSearchBarWindow()
    }
    
    func closeSearchBarWindow() {
        self.resultSerchController.isActive = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Return results based on search in table view
extension MusicViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        presenter.updateSearchResults(for: searchController)
    }
}

// MARK - Initial view settings
extension MusicViewController {
    // Set SearchBar
    func viewInitialization() {
        self.resultSerchController = UISearchController(searchResultsController: nil)
        self.resultSerchController.searchResultsUpdater = self
        self.resultSerchController.dimsBackgroundDuringPresentation = false
        
        let searchBar = self.resultSerchController.searchBar
        searchBar.prompt = "Find background music"
        (searchBar.value(forKey: "searchField") as! UITextField).backgroundColor = UIColor(red: CGFloat(0.867), green: CGFloat(0.875), blue: CGFloat(0.878), alpha: CGFloat(1.00))
        searchBar.barTintColor = UIColor(red: CGFloat(0.984), green: CGFloat(0.984), blue: CGFloat(0.984), alpha: CGFloat(1.00))
        searchBar.sizeToFit()
        
        self.tableView.tableHeaderView = self.resultSerchController.searchBar
    }
}

extension MusicViewController: MusicMvpView {
    // Updates the music item to the table.
    func updateMusicWithTable() {
        tableView.reloadData()
    }
}
