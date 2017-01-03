//
//  SharePresenter.swift
//  Muvigram
//
//  Created by GangGongUi on 2017. 1. 3..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class SharePresenter<T: ShareMvpView>: BasePresenter<T> {

    private let dataManager: DataManager
    private let bag = DisposeBag()
    
    var videoUrl: URL!
    
    // @inject
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    internal func viewDidLoad(url: URL){
        self.videoUrl = url
        self.view?.playVideo()
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
   
}
