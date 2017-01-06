//
//  DataManager.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 26..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import Foundation
import MediaPlayer
import UIKit
import RxSwift

class DataManager {
    
    private let musicService: MusicService
    private let videoService: VideoService
    
    // @inject
    init(musicService: MusicService, videoService: VideoService) {
        self.musicService = musicService
        self.videoService = videoService
    }
    
    public func getMusics() -> Observable<MPMediaItem> {
        return musicService.getMusics()
    }
    
    public func getLastVideoThumbnail() -> Observable<UIImage> {
        return videoService.getLastVideoThumbnail()
    }
    
    public func saveVideoWithUrl(url: URL) -> Observable<Void> {
        return videoService.saveVideoWithURL(url: url)
    }
    
    public func encodeVideofileForMargins(videoUrlArray: [URL],
                                          musicTimeStampArray: [CMTime],
                                          musicUrl: URL) -> Observable<URL> {
        return videoService.encodeVideofileForMargins(videoUrlArray, musicTimeStampArray, musicUrl)
    }
    
    public func clearUnnecessaryfilesForMusicAndVideo(videoUrlArray: inout [URL], musicTimeStampArray: inout [CMTime]) {
    
        videoService.clearUnnecessaryfilesForMusicAndVideo(&videoUrlArray, &musicTimeStampArray)
    
    }
    
    public func removeVideoWithPath(atPath path: String) {
        videoService.removeVideoWithPath(atPath: path)
    }
    
    public func deleteVideofilesTemporary(videoUrlArray: inout [URL], musicTimeStampArray: inout [CMTime], player: inout AVPlayer) {
        videoService.deleteVideofilesTemporary(&videoUrlArray , &musicTimeStampArray, &player)
    }
    
}
