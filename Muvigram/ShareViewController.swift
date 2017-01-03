//
//  ShareViewController.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 19..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import AVFoundation

class ShareViewController: UIViewController {
    
    var videofileUrl: URL?
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //CameraViewController plays the merged video file.
        if let videofileUrl = videofileUrl {
            player = AVPlayer(url: videofileUrl)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.view.bounds
            self.view.layer.addSublayer(playerLayer)
            player?.play()
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [unowned self] _  in
                self.player?.seek(to: kCMTimeZero, completionHandler: { _ in
                    self.player?.play()
                })
            }
        } else {
            print("goni!")
        }
    }
    @IBAction func end(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("deinit")
    }
}
