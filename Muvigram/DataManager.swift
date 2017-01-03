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
        return videoService.getLastVideoThumbnail().asObservable()
    }
    
    public func saveVideoWithUrl(url: URL) -> Observable<Void> {
        return videoService.saveVideoWithURL(url: url)
    }
}
