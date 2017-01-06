//
//  CameraPresenterWithStackbar.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 26..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import Foundation
import UIKit

// Stack Bars and Interactive Presenter
extension CameraPresenter where T:CameraMvpView {
    
    private var stackImageRight: UIImage {
        return UIImage(named: "stackPop_right")!
    }
    
    private var stackImageLeft: UIImage {
        return UIImage(named: "stackPop_left")!
    }
    
    private var stackImage: UIImage {
        return UIImage(named: "stackPop")!
    }
    
    // Update gauge position of stack bar according to current shooting time
    internal func stackChangeWithCoord(_ stackCurredCoord: CGPoint,_ width: CGFloat) {
        // Disable pop button if gauge is 0
        guard stackCurredCoord.x > 0 else {
            self.view?.popButtonHidden(status: true)
            return
        }
        
        // Change the position and shape of the pop button according to the position of the gauge
        let availableSpaceforPlacing: CGFloat = 20
        if stackCurredCoord.x <= availableSpaceforPlacing {
             self.view?.popButtonPositionChangeWithStackBarStatus(
             buttonImage: self.stackImageRight, buttonPosition: CGRect(x: stackCurredCoord.x , y: stackCurredCoord.y + 5, width: 40, height: 40))
        } else if stackCurredCoord.x + availableSpaceforPlacing >= width {
             self.view?.popButtonPositionChangeWithStackBarStatus(
             buttonImage: self.stackImageLeft, buttonPosition: CGRect(x: stackCurredCoord.x - 40, y: stackCurredCoord.y + 5, width: 40, height: 40))
        } else {
             self.view?.popButtonPositionChangeWithStackBarStatus(
             buttonImage: self.stackImage, buttonPosition: CGRect(x: stackCurredCoord.x - availableSpaceforPlacing , y: stackCurredCoord.y + 5, width: 40, height: 40))
        }
        self.view?.popButtonHidden(status: false)
    }
    
    internal func stackBarPop() {
        DispatchQueue.global().async { [unowned self] in
            self.dataManager.deleteVideofilesTemporary(videoUrlArray: &self.videoUrlArray, musicTimeStampArray: &self.musicTimeStampArray, player: &self.recordingModePlayer!)
        }
    }
    
    internal func stackBarStop() {
        self.view?.stackingStopWithStackBar()
        self.view?.controllerViewisHidden(false, isRecord: false)
    }
    internal func minimumRecordingtimeComplete() {
        self.view?.videoEditComplateButtonEnableWithStackBarStatus(status: true)
        self.isStackBarPassminimumRecordingCondition = true
    }
    
    internal func minimumRecordingtimeLess() {
        self.view?.videoEditComplateButtonEnableWithStackBarStatus(status: false)
        self.isStackBarPassminimumRecordingCondition = false
    }
}
