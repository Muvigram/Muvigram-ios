//
//  MusicMvpView.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 26..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import Foundation
import MediaPlayer

@objc protocol MusicMvpView: Mvpview {
    func updateMusicWithTable()
    @objc optional func setWaveformViewAsset(asset: AVAsset)
    @objc optional func setWaveformViewPrecision()
    @objc optional func setWaveformViewTimeRange(range: CMTimeRange)
    @objc optional func setWaveformViewProgress(time: CMTime)
    @objc optional func getWaveformViewTimeRangeStart() -> CMTime
    @objc optional func getWaveformViewAssetDuration() -> CMTime
    @objc optional func showMusicRangeAlert()
}
