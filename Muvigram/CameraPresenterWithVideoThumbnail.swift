//
//  CameraPresenterWithVideoThumbnail.swift
//  Muvigram
//
//  Created by GangGongUi on 2017. 1. 2..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import Foundation

extension CameraPresenter where T:CameraMvpView {
    func loadVideos() {
        self.dataManager.syncLastVideoThumbnail()
            .subscribe(onNext: { image in
                self.view?.setlibraryButtonImage(image)
            }, onError: { (error) in
                print(error.localizedDescription)
            })
            .addDisposableTo(bag)
    }
}
