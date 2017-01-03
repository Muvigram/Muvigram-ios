//
//  MusicPresenter.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 26..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import Foundation
import MediaPlayer
import RxSwift

class MusicPresenter<T: MusicMvpView>: BasePresenter<T> {
    
    private let dataManager: DataManager
    private var allMusicProdcus = [MPMediaItem]()
    private var filteredMusicProducts = [MPMediaItem]()
    // Observer removal role
    private let bag = DisposeBag()
    
    // @inject
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    // Request a music list from dataManager and update it in the view.
    public func loadMusics() {
        dataManager.syncMusics()
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [unowned self] (MPMediaItem) in
                self.allMusicProdcus.append(MPMediaItem)
                self.view?.updateMusicWithTable()
            }, onError: { (Error) in
                print(Error.localizedDescription)
            }).addDisposableTo(bag)
    }
    
    public func getMusicCountWithShouldshow(resultSerchActive: Bool) -> Int {
        if resultSerchActive {
            return filteredMusicProducts.count
        } else {
            return allMusicProdcus.count
        }
    }
    
    public func updateSearchResults(for searchController: UISearchController) {
        filteredMusicProducts.removeAll(keepingCapacity: false)
        filteredMusicProducts = allMusicProdcus.filter {
            (($0.title?.range(of: searchController.searchBar.text!)) != nil )
        }
        self.view?.updateMusicWithTable()
    }
    
    // Bind an item in the music list to a cell.
    public func bindMusicItemCellWithShouldshow(resultSerchActive: Bool, cellForRowAt indexPath: IndexPath,
                             dequeueReusableCellFunction: (String) -> UITableViewCell?) -> UITableViewCell {
        let cell = dequeueReusableCellFunction("MusicItemCell")!
        let musicItemCell = cell as! MusicTableViewCell
        if resultSerchActive {
            musicItemCell.bind(item: filteredMusicProducts[indexPath.row])
        } else {
            musicItemCell.bind(item: allMusicProdcus[indexPath.row])
        }
        return cell
    }
}
