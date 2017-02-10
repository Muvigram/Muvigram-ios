//
//  ShareViewController.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 19..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import RxSwift
import PopupDialog
import AVFoundation

class ShareViewController: UIViewController {
    
    var videoUrlArray: [URL]!
    var musicTimeStampArray: [CMTime]!
    var musicUrl: URL!
    var player: AVPlayer?
    
    var dismissFunc: (() -> Void)?
    
    fileprivate var periodicTimeToken: Any? = nil
    
    // @inject
    public var presenter: SharePresenter<ShareViewController>!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    //@IBOutlet var shareButton: UIButton!
    //@IBOutlet var instagramShareButton: UIButton!
    
    override func viewDidLoad() {
        

        super.viewDidLoad()
        self.dismissFunc?()
        
        self.presenter.encodeVideofileForMargins(videoUrlArray: videoUrlArray, musicTimeStampArray: musicTimeStampArray, musicUrl: musicUrl)
        
        let saveButtonEvent = saveButton.rx.controlEvent(UIControlEvents.touchUpInside)
        presenter.saveButtonClickEvent(event: saveButtonEvent)
        
        let homeButtonEvent = homeButton.rx.controlEvent(UIControlEvents.touchUpInside)
        presenter.homeButtonClickEvent(event: homeButtonEvent)
        
        //let shareButtonEvent = shareButton.rx.controlEvent(UIControlEvents.touchUpInside)
        //presenter.shareButtonClickEvent(event: shareButtonEvent)
        
        /*
         let instagramButtonEvent = instagramShareButton.rx.controlEvent(UIControlEvents.touchUpInside)
         presenter.instagramButtonClickEvent(event: instagramButtonEvent)
         */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        player?.play()
    }
    
    deinit {
        print("deinit")
        modifyPlayerRemoveTimeObserver()
    }
    
    private func modifyPlayerRemoveTimeObserver() {
        if let token = self.periodicTimeToken {
            self.player?.removeTimeObserver(token)
            self.periodicTimeToken = nil
        }
    }
    
    @IBAction func homeClick(_ sender: Any) {
        dimissShareViewController()
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
            
            let timeResolution: Int32 = 60000000
            
            // Repeat until the last time so that the logo is not exposed
            let videoDuratoin = AVURLAsset(url: videofileUrl, options: nil).duration
            var videoRepeatcheck = true
            
            self.periodicTimeToken = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, timeResolution), queue: DispatchQueue.main, using: { (time) in
                if time >= videoDuratoin, videoRepeatcheck {
                    videoRepeatcheck = false
                    self.player?.seek(to: kCMTimeZero) { _ in
                        self.player?.play()
                        videoRepeatcheck = true
                    }
                }
            })
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
    
    func dimissShareViewController() {
        self.player?.pause()
        self.player = nil
        presenter = nil
        self.dismiss(animated: true, completion: nil);
    }
    
    func showCompleteDialog() {
        self.present(PopupDialog(title: "Save is complete.", message: ""), animated: true, completion: nil)
    }
    
    func showShareSheet(videoUrl: URL) {
        let activityViewController = UIActivityViewController(activityItems: [videoUrl], applicationActivities: nil)
        activityViewController.setValue("Video", forKey: "subject")
        
        if #available(iOS 9.0, *) {
            activityViewController.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.assignToContact, UIActivityType.copyToPasteboard, UIActivityType.mail, UIActivityType.message, UIActivityType.openInIBooks, UIActivityType.postToTencentWeibo, UIActivityType.postToVimeo, UIActivityType.postToWeibo, UIActivityType.print]
        } else {
            // Fallback on earlier versions
            activityViewController.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.assignToContact, UIActivityType.copyToPasteboard, UIActivityType.mail, UIActivityType.message, UIActivityType.postToTencentWeibo, UIActivityType.postToVimeo, UIActivityType.postToWeibo, UIActivityType.print ]
        }
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func enabledSaveButton(isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
    }
}
