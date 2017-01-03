//
//  MusicService.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 25..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import Foundation
import MediaPlayer
import RxSwift

class MusicService {
    // Returns a list of music files.
    public func getMusics() -> Observable<MPMediaItem> {
        if let musicList = MPMediaQuery.songs().items {
            return Observable.from(musicList)
        } else {
            return Observable.from([MPMediaItem]())
        }
    }
}
