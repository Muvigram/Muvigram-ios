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
    
    public func syncMusics() -> Observable<MPMediaItem> {
        return musicService.getMusics()
    }
    
    public func syncLastVideoThumbnail() -> Observable<UIImage> {
        return videoService.getLastVideoThumbnail().asObservable()
    }
}
