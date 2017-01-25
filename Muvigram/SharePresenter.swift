//
//  SharePresenter.swift
//  Muvigram
//
//  Created by GangGongUi on 2017. 1. 3..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import RxCocoa
import RxSwift
import Photos

class SharePresenter<T: ShareMvpView>: BasePresenter<T> {

    private let dataManager: DataManager
    private let bag = DisposeBag()
    private var videoUrl: URL!
    
    // @inject
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    internal func encodeVideofileForMargins(videoUrlArray: [URL],
                                          musicTimeStampArray: [CMTime],
                                          musicUrl: URL) {
        let (indicator, contrainer) = (self.view?.createActivityIndicatory(uiView: (self.view as! ShareViewController).view))!
        indicator.startAnimating()
        self.dataManager.encodeVideofileForMargins(videoUrlArray: videoUrlArray,
                                                   musicTimeStampArray: musicTimeStampArray,
                                                   musicUrl: musicUrl)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { encodeVideourl in
                self.videoUrl = encodeVideourl
                self.view?.playVideo(mergedVideofileUrl: encodeVideourl)
            }, onError: { error in
                print(error)
            }, onCompleted: {
                indicator.stopAnimating()
                contrainer.removeFromSuperview()
                self.removeVideoWithPaths(videoUrlArray: videoUrlArray)
            }).addDisposableTo(bag)
    }
    
    internal func homeButtonClickEvent(event: ControlEvent<Void>) {
        event.debounce(0.2, scheduler: MainScheduler.instance)
            .bindNext {
                self.view?.dimissShareViewController()
        }.addDisposableTo(bag)
    }
 
    internal func saveButtonClickEvent(event: ControlEvent<Void>) {
        event.debounce(0.2, scheduler: MainScheduler.instance)
            .bindNext { [unowned self] in
                self.saveVideoWithURL() {
                    self.view?.showCompleteDialog()
                }
            }.addDisposableTo(bag)
    }
    
    internal func shareButtonClickEvent(event: ControlEvent<Void>) {
        event.debounce(0.2, scheduler: MainScheduler.instance)
            .bindNext {
                //self.view?.enabledSaveButton(isEnabled: false)
                self.view?.showShareSheet(videoUrl: self.videoUrl)
                
        }.addDisposableTo(bag)
    }
    
    private func saveVideoWithURL(completionHandler: (() -> Void)?) {
        let (indicator, contrainer) = (self.view?.createActivityIndicatory(uiView: (self.view as! ShareViewController).view))!
        indicator.startAnimating()
        self.dataManager.saveVideoWithUrl(url: self.videoUrl)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .subscribe(
                onError: { error in
                    print(error.localizedDescription)
                },
                onCompleted: {
                    indicator.stopAnimating()
                    contrainer.removeFromSuperview()
                    completionHandler?()
                }).addDisposableTo(self.bag)
    }
    
    internal func removeVideoWithPaths(videoUrlArray: [URL]) {
        DispatchQueue.global().async {
            for url in videoUrlArray {
                self.dataManager.removeVideoWithPath(atPath: url.path)
            }
        }
    }
    
    /*internal func instagramButtonClickEvent(event: ControlEvent<Void>) {
     event.debounce(0.2, scheduler: MainScheduler.instance)
     .bindNext {
     self.dataManager.saveVideoWithUrl(url: self.videoUrl)
     .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
     .observeOn(MainScheduler.instance)
     .subscribe(
     onError: { error in
     print(error.localizedDescription)
     },
     onCompleted: {
     let instagramURL = URL(string: "instagram://camera")
     if UIApplication.shared.canOpenURL(instagramURL!) {
     UIApplication.shared.open(instagramURL!)
     }
     self.view?.dimissShareViewController()
     })
     .addDisposableTo(self.bag)
     }.addDisposableTo(bag)
     }*/
}
