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
    
    var videoUrlArray: [URL]!
    var musicTimeStampArray: [CMTime]!
    var musicUrl: URL!

    var player: AVPlayer?
    
    // @inject
    public var presenter: SharePresenter<ShareViewController>!
    @IBOutlet var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.presenter.encodeVideofileForMargins(videoUrlArray: videoUrlArray, musicTimeStampArray: musicTimeStampArray, musicUrl: musicUrl)
        
        let saveButtonEvent = saveButton.rx.controlEvent(UIControlEvents.touchUpInside)
        presenter.saveButtonClickEvent(event: saveButtonEvent)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("deinit")
    }
    
}

extension ShareViewController: ShareMvpView {
    // Called when encodeVideofileForMargins () is finished
    func playVideo(mergedVideofileUrl: URL?) {
        if let videofileUrl = mergedVideofileUrl {
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
    
    // Create loading indicator
    func createActivityIndicatory(uiView: UIView) -> (UIActivityIndicatorView, UIView) {
        let container: UIView = UIView()
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.0)
        
        let loadingView: UIView = UIView()
        
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(0.5))
        
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        
        actInd.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.whiteLarge
        
        actInd.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2);
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        return (actInd, container)
    }
}
