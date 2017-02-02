//
//  MusicPresenter.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 26..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer
import RxSwift
import RxCocoa

class MusicPresenter<T: MusicMvpView>: BasePresenter<T> {
    
    private let dataManager: DataManager
    private var allMusicProdcus = [MPMediaItem]()
    private var filteredMusicProducts = [MPMediaItem]()
    private var musicUrl: URL?
    private var isModifyModePlayerPlay: Bool = true
    private var modifyModePlayer: AVPlayer?
    private var musicInputTime: CMTime = kCMTimeZero
    private var musicOutputTime: CMTime = CMTime(seconds: 15, preferredTimescale: 1)
    private var periodicTimeToken: Any? = nil
    // Observer removal role
    private let bag = DisposeBag()
    
    // @inject
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    // Request a music list from dataManager and update it in the view.
    public func loadMusics() {
        dataManager.getMusics()
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
    
    public func skipButtonEvent(event: ControlEvent<Void>) {
        event.debounce(0.3, scheduler: MainScheduler.instance)
            . bindNext { [unowned self] in
                self.moveToVideoEditorController()
        }.addDisposableTo(bag)
    }
    
    public func backButtonEvent(event: ControlEvent<Void>) {
        event.debounce(0.3, scheduler: MainScheduler.instance)
            . bindNext { [unowned self] in
                self.view?.dismissController!()
            }.addDisposableTo(bag)
    }
    
    public func moveToVideoEditorController() {
        self.view?.movetoVideoEditerViewController!(musicInputTime: self.musicInputTime, musicOutputTime: self.musicOutputTime, musicUrl: self.musicUrl)
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
    
    public func selectMusic(musicUrl: URL) {
        self.musicUrl = musicUrl
        self.view?.setWaveformViewAsset?(asset: AVAsset(url: musicUrl))
        self.view?.setWaveformViewPrecision?()
        var duration = CMTimeMakeWithSeconds( 1.0 * CMTimeGetSeconds((self.view!.getWaveformViewAssetDuration?())!), 100000)
        self.view?.setWaveformViewTimeRange!(range: CMTimeRangeMake(CMTimeMakeWithSeconds(0, 10000), duration))
        
        var start = self.view!.getWaveformViewTimeRangeStart?()
        duration = CMTime(seconds: 15, preferredTimescale: 1)
        
        let scwaveDuration = self.view!.getWaveformViewAssetDuration?()
        
        // Adjusting the start time
        if CMTimeAdd(start!, duration) > scwaveDuration! {
            start = CMTimeSubtract(scwaveDuration!, duration);
        }
        self.view?.setWaveformViewTimeRange!(range: CMTimeRangeMake(start!, duration))
        self.view?.showMusicRangeAlert?()
    }
    
    public func setModifyPlayerRange(_ range: CMTimeRange, end: CMTime) {
        self.musicInputTime = range.start
        self.musicOutputTime = range.end
    }
    
    public func modifyPlayerPause() {
        modifyModePlayer?.pause()
        
    }
    
    public func modifyPlayerRemoveTimeObserver() {
        if let token = self.periodicTimeToken {
            modifyModePlayer?.removeTimeObserver(token)
            self.periodicTimeToken = nil
        }
    }
    
    public func modifyPlayerPlay() {
        modifyModePlayer?.seek(to: self.musicInputTime, completionHandler: { _ in
            self.modifyModePlayer?.play()
        })
    }
    
    public func musicSectionSelectionPlayback() {
        DispatchQueue.global().async { [unowned self] in
            if let url = self.musicUrl {
                self.modifyModePlayer = AVPlayer(playerItem: AVPlayerItem(url: url))
                self.modifyModePlayer?.seek(to: self.musicInputTime)
                self.modifyModePlayer?.play()
                
                let actualMusicEndSec = CMTimeGetSeconds((self.modifyModePlayer?.currentItem?.asset.duration)!)
                
                self.modifyPlayerRemoveTimeObserver()
                self.periodicTimeToken = self.modifyModePlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 60), queue: DispatchQueue.main, using: { (time) in
                    let currentMusicSec = CMTimeGetSeconds(time)
                    let endMusicSec = CMTimeGetSeconds(self.musicOutputTime)
                    
                    if currentMusicSec >= endMusicSec || currentMusicSec >= actualMusicEndSec {
                        if self.isModifyModePlayerPlay {
                            self.isModifyModePlayerPlay = false
                            self.view?.setWaveformViewProgress!(time: self.musicInputTime)
                            self.modifyModePlayer?.pause()
                            self.modifyModePlayer?.seek(to: self.musicInputTime) { _ in
                                self.modifyModePlayer?.play()
                                self.isModifyModePlayerPlay = true
                            }
                        }
                    } else {
                        self.view?.setWaveformViewProgress!(time: time)
                    }
                })
            } else {
                print("No music files")
            }
        }
    }
}
