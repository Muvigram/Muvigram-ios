//
//  PreviewView.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 11. 30..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // 레이어
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
