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
 
    internal func saveButtonClickEvent(event: ControlEvent<Void>) {
        event
            .debounce(1.0, scheduler: MainScheduler.instance)
            .bindNext { [unowned self] in
                self.dataManager.saveVideoWithUrl(url: self.videoUrl)
                    .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
                    .observeOn(MainScheduler.instance)
                    .subscribe(
                        onError: { error in
                            print(error.localizedDescription)
                    },
                        onCompleted: {
                            print("completed")
                    })
                    .addDisposableTo(self.bag)
        }.addDisposableTo(bag)
    }
    
    internal func removeVideoWithPaths(videoUrlArray: [URL]) {
        DispatchQueue.global().async {
            for url in videoUrlArray {
                self.dataManager.removeVideoWithPath(atPath: url.path)
            }
        }
    }
    
}
