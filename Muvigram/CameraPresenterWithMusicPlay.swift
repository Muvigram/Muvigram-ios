//
//  CameraPresenterWithMusicPlay.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 26..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import Permission
import MediaPlayer
import RxSwift
import RxCocoa
import SCWaveformView

extension CameraPresenter where T:CameraMvpView {
    
    internal func selectMusicfromList(item: MPMediaItem) {
        
        // Now that your music is reset, let it know it's the first time you're playing it.
        self.isRecordingModeFirstRun = true
        // Disable recording complete button because music is newly selected
        self.view?.videoEditComplateButtonEnableWithStackBarStatus(status: false)
        
        if let artwork = item.artwork {
            self.view?.musicAlbumImageReplace(albumImage: artwork.image(at: CGSize(width: 40, height: 40))!)
        } else {
            self.view?.musicAlbumImageReplace(albumImage: UIImage(named: "noAlbumArt")!)
        }
        
        musicUrl = item.assetURL
        recordingModePlayer = AVPlayer(playerItem: AVPlayerItem(url: musicUrl!))
        
        addPreiodicTimeObserver()
        
        let musicAsset = AVAsset(url: (item.assetURL)!)
        
        self.view?.setWaveformViewAsset(asset: musicAsset)
        self.view?.setWaveformViewPrecision()
        
        
        var duration = CMTimeMakeWithSeconds( 1.0 * CMTimeGetSeconds(self.view!.getWaveformViewAssetDuration()), 100000)
        
        self.view?.setWaveformViewTimeRange(range: CMTimeRangeMake(CMTimeMakeWithSeconds(0, 10000), duration))
        
        var start = self.view!.getWaveformViewTimeRangeStart()
        duration = CMTime(seconds: 15, preferredTimescale: 1)
        
        let scwaveDuration = self.view!.getWaveformViewAssetDuration()
        
        // Adjusting the start time
        if CMTimeAdd(start, duration) > scwaveDuration {
            start = CMTimeSubtract(scwaveDuration, duration);
        }
        self.view?.setWaveformViewTimeRange(range: CMTimeRangeMake(start, duration))
    }
    
    // Play the music you selected.
    // Repeats only the 15 second waveform displayed to the current user.
    internal func musicSectionSelectionPlayback() {
        DispatchQueue.global().async { [unowned self] in
            
            var isPause = false
            
            if let url = self.musicUrl {
                self.modifyModePlayer = AVPlayer(playerItem: AVPlayerItem(url: url))
                self.modifyModePlayer?.seek(to: self.musicInputTime)
                self.modifyModePlayer?.play()
                
                let actualMusicEndSec = CMTimeGetSeconds((self.modifyModePlayer?.currentItem?.asset.duration)!)
                
                self.modifyModePlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 60), queue: DispatchQueue.main, using: { (time) in
                    let currentMusicSec = CMTimeGetSeconds(time)
                    let endMusicSec = CMTimeGetSeconds(self.musicOutputTime)
                    
                    if currentMusicSec >= endMusicSec || currentMusicSec >= actualMusicEndSec {
                        if !isPause {
                            isPause = true
                            self.modifyModePlayer?.pause()
                            self.modifyModePlayer?.seek(to: self.musicInputTime, completionHandler: { _ in
                                self.view?.setWaveformViewProgress(time: self.musicInputTime)
                                self.modifyModePlayer?.play()
                                isPause = false
                            })
                        }
                    } else {
                        self.view?.setWaveformViewProgress(time: time)
                    }
                })
            } else {
                print("No music files")
            }
        }
    }
    
    internal func addPreiodicTimeObserver() {
        let actualMusicEndSec = CMTimeGetSeconds((self.recordingModePlayer?.currentItem?.asset.duration)!)
        
        // Observe the current playback position of the music file,
        // and stop playback when it is over 15 seconds.
        self.recordingModePlayer?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 60), queue: DispatchQueue.main, using: { (time) in
            
            let currentMusicSec = CMTimeGetSeconds(time)
            
            let endMusicSec = CMTimeGetSeconds(self.musicOutputTime)
            let startMusicSec = CMTimeGetSeconds(self.musicInputTime)
            
            // When the current playback time exceeds the actual
            // file time of 15 seconds, recording stops.
            if currentMusicSec >= endMusicSec || currentMusicSec >= actualMusicEndSec {
                self.view?.recordButtonSendActionTouchUpInside()
            } else {
                // Stack bar update
                let offset = currentMusicSec - startMusicSec
                self.view?.stackingStartWithStackBar(time: offset)
            }
        })
    }
    
    // Called when playing music for the first time.
    internal func playMusicOnRecording() {
        DispatchQueue.global().async { [unowned self] in
            self.musicTimeStampArray.removeAll()
            
            // Set intervals and play music using music url.
            self.recordingModePlayer?.seek(to: self.musicInputTime, completionHandler: {_ in
                self.recordingModePlayer?.play()
            })
            self.isRecordingModeFirstRun = false
            self.musicTimeStampArray.append(self.musicInputTime)
        }
    }
    
    // Stop music
    internal func stopMusic() {
        self.recordingModePlayer?.pause()
        self.musicTimeStampArray.append((self.recordingModePlayer?.currentTime())!)
    }
    
    internal func modifyPlayerPause() {
        self.modifyModePlayer?.pause()
    }
    
    internal func modifyPlayerPlay() {
        self.modifyModePlayer?.seek(to: self.musicInputTime, completionHandler: { _ in
            self.modifyModePlayer?.play()
        })
    }
    
    internal func setModifyPlayerRange(_ range: CMTimeRange, end: CMTime) {
        self.musicInputTime = range.start
        self.musicOutputTime = range.end
    }
    
    internal func touchTestShow() {
        self.modifyModePlayer?.pause()
        
        self.view?.scrollExclusiveOr(true)
        self.view?.controllerViewisHidden(false, isRecord: false)
    }
}
