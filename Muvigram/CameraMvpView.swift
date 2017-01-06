//
//  CameraMvpView.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 26..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

protocol CameraMvpView: Mvpview {
    
    func popButtonHidden(status: Bool)
    
    func videoEditComplateButtonEnableWithStackBarStatus(status: Bool)
    
    func popButtonPositionChangeWithStackBarStatus(buttonImage: UIImage, buttonPosition: CGRect)
    
    func audioEditButtonEnabled(enabled: Bool)
    
    func recordButtonEnabled(enabled: Bool)
    
    func switchCameraButtonEnabled(enabled: Bool)
    
    func musicAlbumImageReplace(albumImage: UIImage)
    
    func stackingStartWithStackBar(time: Float64)
    
    func stackingStopWithStackBar()
    
    func recordButtonSendActionTouchUpInside()
    
    func setWaveformViewAsset(asset: AVAsset)
    
    func setWaveformViewPrecision()
    
    func setWaveformViewTimeRange(range: CMTimeRange)
    
    func setWaveformViewProgress(time: CMTime)
    
    func getWaveformViewTimeRangeStart() -> CMTime
    
    func getWaveformViewAssetDuration() -> CMTime
    
    func partialRecordingComplete()
    
    func partialRecordingStarted()
    
    func scrollExclusiveOr(_ enabled: Bool)
    
    func videoRecordingFinalized(videoUrlArray: [URL], musicTimeStampArray: [CMTime], musicUrl: URL)
    
    func controllerViewisHidden(_ hidden: Bool, isRecord: Bool)
    
    func moveToMusicViewController()
    
    func setlibraryButtonImage(_ image: UIImage)
}
