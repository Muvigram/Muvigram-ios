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
    internal var isCompleateRecored: Bool = false
    public let dataManager: DataManager
    let mp3Path = Bundle.main.path(forResource: "Silence_15_sec", ofType: "mp3")
    
    // @inject
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    // A stack of music taken by the user
    internal var musicCurrentTimeStack = [CMTime]() {
        didSet {
            if musicCurrentTimeStack.isEmpty {
                self.isRecordingModeFirstRun = true
            }
        }
    }
    
    // A stack of video taken by the user
    internal var videoFileUrlStack = [URL]() {
        didSet {
            self.view?.scrollExclusiveOr(videoFileUrlStack.isEmpty)
            if videoFileUrlStack.isEmpty {
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
        self.cleanVideoandMusicStack()
    }
    
    internal func deleteVideofilesTemporary() {
        guard !videoFileUrlStack.isEmpty else {
            return
        }
        DispatchQueue.global().async {
            let stackTopFilePath = self.videoFileUrlStack.popLast()?.path
            self.removeVideoFile(outputFilePath: stackTopFilePath!)
            
            // Changes the stack bar to the time of the previously recorded video.
            _ = self.musicCurrentTimeStack.popLast()
            if let lastTime = self.musicCurrentTimeStack.last, self.musicCurrentTimeStack.count >= 2 {
                self.recordingModePlayer?.seek(to: lastTime)
            } else {
                _ = self.musicCurrentTimeStack.popLast()
            }
        }
    }
    
    internal func cleanVideoandMusicStack() {
        DispatchQueue.global().async {
            for videoFileUrl in self.videoFileUrlStack {
                self.removeVideoFile(outputFilePath: videoFileUrl.path)
            }
            self.musicCurrentTimeStack.removeAll()
            self.videoFileUrlStack.removeAll()
        }
    }
    
    internal func removeVideoFile(outputFilePath: String) {
        let path = outputFilePath
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            }
            catch {
                print("Could not remove file at path: \(path)")
            }
        }
    }
    
    // Merging video files.
    internal func margeAudioandVideoFiles(compleate: @escaping (URL) -> Void) {
        DispatchQueue.global().async { [unowned self] in
            let compostion = AVMutableComposition()
            let trackVideo: AVMutableCompositionTrack
                = compostion.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
            let trackAudio: AVMutableCompositionTrack
                = compostion.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
            var insertTime = kCMTimeZero
            
            // 비디오를 가로로 돌려줍니다.
            trackVideo.preferredTransform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2));
            
            print(self.videoFileUrlStack.count)
            print(self.musicCurrentTimeStack.count)
            
            for time in self.musicCurrentTimeStack {
                print("\(CMTimeGetSeconds(time))")
            }
            
            let audeoAsset = AVURLAsset(url: self.musicUrl!)
            let audios = audeoAsset.tracks(withMediaType: AVMediaTypeAudio)
            let assetTrackAudio = audios.first!
            
            for (idx, videoUrl) in self.videoFileUrlStack.enumerated() {
                let videoAsset = AVURLAsset(url: videoUrl)
                let tracks = videoAsset.tracks(withMediaType: AVMediaTypeVideo)
                
                if tracks.count > 0 {
                    do {
                        
                        let duration = CMTime(seconds: CMTimeGetSeconds(self.musicCurrentTimeStack[idx+1]) - CMTimeGetSeconds(self.musicCurrentTimeStack[idx]), preferredTimescale: 2000000000)
                        
                        let assetTrackVedio = tracks.first!
                        try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration),
                                                       of: assetTrackVedio, at: insertTime)
                        
                        try trackAudio.insertTimeRange(CMTimeRangeMake(self.musicCurrentTimeStack[idx], duration),
                                                       of: assetTrackAudio, at: insertTime)
                        
                        print("idx -> \(idx)")
                        print("music time ->   #1       \(CMTimeGetSeconds(duration))")
                        print("video time ->   #3       \(CMTimeGetSeconds(duration))")
                        
                        // 병합 시작 위치 갱신
                        insertTime = CMTimeAdd(insertTime, duration)
                    } catch {
                        print("mergeVideoFile insertTimeRange error")
                    }
                }
            }
            
            // 병합한 비디오가 쓰여질 경로 지정
            let combinedVideoName = UUID().uuidString
            let combinedVideoFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((combinedVideoName as NSString).appendingPathExtension("mov")!)
            let combinedVideoUrl = URL(fileURLWithPath: combinedVideoFilePath)
            
            // 병합한 비디오 쓰기
            if let exportSession = AVAssetExportSession(asset: compostion, presetName: AVAssetExportPresetHighestQuality){
                
                exportSession.outputURL = combinedVideoUrl
                exportSession.outputFileType = AVFileTypeMPEG4
                exportSession.exportAsynchronously(completionHandler: {
                    switch exportSession.status {
                    case .failed:
                        print("failed\(exportSession.error)")
                    case .cancelled:
                        print("cancelled\(exportSession.error)")
                    default:
                        // 병합한 비디오파일을 쓰는 것에 성공하였다면 완료 호출
                        DispatchQueue.main.sync {
                            compleate(combinedVideoUrl)
                        }
                        // 임시 파일 삭제
                        self.cleanVideoandMusicStack()
                    }
                })
            }
        }
    }
    
    internal func capture(didFinishRecordingToOutputFileAt outputFileURL: URL!) {
        // Saved shot path
        videoFileUrlStack.append(outputFileURL)
        self.view?.recordButtonEnabled(enabled: true)
        
        if self.isCompleateRecored {
            self.view?.videoRecordingFinalized()
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
                let curRecordedTime = CMTimeGetSeconds(self.recordingModePlayer!.currentTime()) - CMTimeGetSeconds(self.musicCurrentTimeStack.last!)
                let cumulativeDuration = CMTimeGetSeconds((self.recordingModePlayer?.currentTime())!) - CMTimeGetSeconds(self.musicCurrentTimeStack.first!)
                
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
                self.view?.videoRecordingFinalized()
             }.addDisposableTo(bag)
    }
    
    internal func isVidioFileUrlEmpty() -> Bool {
        return self.videoFileUrlStack.isEmpty
    }
}




