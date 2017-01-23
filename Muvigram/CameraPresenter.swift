//
//  CameraPresenter.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 26..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import MediaPlayer
import Foundation
import RxSwift
import RxCocoa
import UIKit

class CameraPresenter<T: CameraMvpView>: BasePresenter<T> {
    // Observer removal role
    internal let bag = DisposeBag()
    internal var isRecordingModeFirstRun = true
    internal var isStackBarPassminimumRecordingCondition = false
    internal var isCompleateRecored: Bool = false
    public let dataManager: DataManager
    let mp3Path = Bundle.main.path(forResource: "Silence_15_sec", ofType: "mp3")
    
    // @inject
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    // A stack of music taken by the user
    internal var musicTimeStampArray = [CMTime]() {
        didSet {
            if musicTimeStampArray.isEmpty {
                self.isRecordingModeFirstRun = true
            }
        }
    }
    
    // A stack of video taken by the user
    internal var videoUrlArray = [URL]() {
        didSet {
            self.view?.scrollExclusiveOr(videoUrlArray.isEmpty)
            if videoUrlArray.isEmpty {
                DispatchQueue.main.sync {
                    self.view?.switchCameraButtonEnabled(enabled: true)
                    if musicUrl?.path != mp3Path! {
                        // Can not edit music files without sound
                        self.view?.audioEditButtonEnabled(enabled: true)
                    }
                }
            }
        }
    }
    
    // User selected music file url
    internal var musicUrl: URL?
    internal var recordingModePlayer: AVPlayer?
    internal var modifyModePlayer: AVPlayer?
    
    // Music play time and end time
    internal var musicInputTime: CMTime = kCMTimeZero
    internal var musicOutputTime: CMTime = CMTime(seconds: 15, preferredTimescale: 1)
    
    // A Bool variable that determines whether to start
    // recording when the user presses the button in succession
    private var isbuttonPressed: Bool = false
    
    internal func viewDidLoad() {
        self.musicUrl = URL(fileURLWithPath: mp3Path!)
        let recordingItem = AVPlayerItem(url: musicUrl!)
        recordingModePlayer = AVPlayer(playerItem: recordingItem)
        addPreiodicTimeObserver()
    }
    
    internal func viewWillAppear() {
        self.isCompleateRecored = false
        clearMusicAndVideo()
    }
    
    internal func clearMusicAndVideo(){
        DispatchQueue.global().async { [unowned self] in
            self.dataManager.clearUnnecessaryfilesForMusicAndVideo(videoUrlArray: &self.videoUrlArray,
                                                                   musicTimeStampArray: &self.musicTimeStampArray)
        }
    }
    
    internal func capture(didFinishRecordingToOutputFileAt outputFileURL: URL!) {
        // Saved shot path
        videoUrlArray.append(outputFileURL)
        self.view?.recordButtonEnabled(enabled: true)
        
        if self.isCompleateRecored {
            self.view?.videoRecordingFinalized(videoUrlArray: videoUrlArray,
                                               musicTimeStampArray: musicTimeStampArray, musicUrl: self.musicUrl!)
        }
    }
    
    internal func captureWithFileWrite() {
        // Play music when you start writing video files to increase the sync rate of music and videos.
        if !self.isRecordingModeFirstRun {
            self.recordingModePlayer?.play()
        }
    }
    
    internal func recordButtonStopRecordEvent(event: ControlEvent<Void>){
        event
            .filter({
                self.isbuttonPressed = false
                if self.recordingModePlayer?.timeControlStatus == .playing {
                    self.view?.recordButtonEnabled(enabled: false)
                    let curRecordedTime = CMTimeGetSeconds(self.recordingModePlayer!.currentTime()) - CMTimeGetSeconds(self.musicTimeStampArray.last!)
                    let cumulativeDuration = CMTimeGetSeconds((self.recordingModePlayer?.currentTime())!) - CMTimeGetSeconds(self.musicTimeStampArray.first!)
                    
                    if cumulativeDuration > 14.0 {
                        let time = DispatchTime.now() + 15.0 - cumulativeDuration
                        DispatchQueue.main.asyncAfter(deadline: time) {
                            self.isCompleateRecored = true
                            self.stopMusic()
                            self.stackBarStop()
                        }
                    } else if curRecordedTime < 1.0 {
                        let time = DispatchTime.now() + 1.0 - curRecordedTime
                        DispatchQueue.main.asyncAfter(deadline: time) {
                            self.stopMusic()
                            self.stackBarStop()
                        }
                    } else {
                        self.stopMusic()
                        self.stackBarStop()
                    }
                    return true
                }
                return false
            })
            .debounce(1.0, scheduler: MainScheduler.instance)
            .bindNext { [unowned self] in
                self.view?.partialRecordingComplete()
                if self.isStackBarPassminimumRecordingCondition {
                    let time = DispatchTime.now() + 0.3
                    DispatchQueue.main.asyncAfter(deadline: time) {
                        self.view?.videoEditComplateButtonEnableWithStackBarStatus(status: true)
                    }
                }
            }.addDisposableTo(bag)
    }
    
    internal func recordButtonStartRecordEvent(event: ControlEvent<Void>) {
        event.filter({
            if self.recordingModePlayer?.timeControlStatus == .paused {
                self.isbuttonPressed = true
                return true
            }
            return false
        })
            .debounce(0.3, scheduler: MainScheduler.instance)
            .bindNext{
                if self.isbuttonPressed {
                    // recording start
                    if self.isRecordingModeFirstRun {
                        self.playMusicOnRecording()
                    }
                    self.view?.partialRecordingStarted()
                    self.view?.controllerViewisHidden(true, isRecord: true)
                    self.view?.videoEditComplateButtonEnableWithStackBarStatus(status: false)
                    
                }
            }.addDisposableTo(bag)
    }
    
    internal func musicSelectButtonEvent(event: ControlEvent<Void>) {
        event.debounce(0.3, scheduler: MainScheduler.instance)
            .bindNext{ [unowned self] in
                self.view?.moveToMusicViewController()
            }.addDisposableTo(bag)
    }
    
    internal func audioEditButtonEvent(event: ControlEvent<Void>) {
        event.debounce(0.3, scheduler: MainScheduler.instance)
            .bindNext{
                self.view?.scrollExclusiveOr(false)
                self.view?.controllerViewisHidden(true, isRecord: false)
                self.musicSectionSelectionPlayback()
            }.addDisposableTo(bag)
    }
    
    internal func videoEditComplateButtonEvent(event: ControlEvent<Void>) {
        event.debounce(0.3, scheduler: MainScheduler.instance)
            .bindNext{
                self.view?.videoRecordingFinalized(videoUrlArray: self.videoUrlArray,
                                                   musicTimeStampArray: self.musicTimeStampArray,
                                                   musicUrl: self.musicUrl!)
            }.addDisposableTo(bag)
    }
    
    internal func isVidioFileUrlEmpty() -> Bool {
        return self.videoUrlArray.isEmpty
    }
}

