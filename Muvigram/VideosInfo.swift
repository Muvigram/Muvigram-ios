//
//  VideosInfo.swift
//  Muvigram
//
//  Created by 박정이 on 2017. 1. 10..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import Foundation
import CTAssetsPickerController

class VideosInfo {
    var videoCount:Int = 0
    var videoList:[PHAsset] = []
    var videoURL:[NSURL] = []
    var playerList:[AVPlayer] = []
    var order:[Int] = []
    var range:[CMTimeRange] = []
    
    var isVertical:[Bool] = []
}
