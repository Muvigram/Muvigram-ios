//
//  ShareViewController.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 19..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import RxSwift
import AVFoundation

class ShareViewController: UIViewController {
    
    var videofileUrl: URL?
    var player: AVPlayer?
    
    // @inject
    public var presenter: SharePresenter<ShareViewController>!
    @IBOutlet var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad(url: videofileUrl!)
        
        let saveButtonEvent = saveButton.rx.controlEvent(UIControlEvents.touchUpInside)
        presenter.saveButtonClickEvent(event: saveButtonEvent)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("deinit")
    }
}

extension ShareViewController: ShareMvpView {
    //CameraViewController plays the merged video file.
    func playVideo() {
        if let videofileUrl = videofileUrl {
            player = AVPlayer(url: videofileUrl)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.bounds = self.view.bounds
            playerLayer.frame = CGRect(x: 0, y: 0, width: self.view.layer.frame.width, height: self.view.layer.frame.height)
            
            self.view.layer.insertSublayer(playerLayer, at: 0)
            player?.play()
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [unowned self] _  in
                self.player?.seek(to: kCMTimeZero, completionHandler: { _ in
                    self.player?.play()
                })
            }
        }
    }
}
