//
//  VideoThumnailService.swift
//  Muvigram
//
//  Created by GangGongUi on 2017. 1. 2..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import Foundation
import RxSwift
import Photos

class VideoService {
    // Returns a video thumbnail Subject
    // Use Subject to resolve asynchronous issues
    public func getLastVideoThumbnail() -> PublishSubject<UIImage> {
        let lastVideoOptions = PHFetchOptions()
        lastVideoOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        lastVideoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        lastVideoOptions.fetchLimit = 1
        let lastVideoPHAsset = PHAsset.fetchAssets(with: lastVideoOptions).firstObject
        let subject = PublishSubject<UIImage>()
        PHImageManager.default().requestImage(for: lastVideoPHAsset!, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: nil) { image, _ in
            if let image = image {
                subject.onNext(image)
            } else {
                subject.onError(NSError(domain: "VIDEO IMAGE IS NIL", code: 404, userInfo: nil))
            }
        }
        return subject
    }
}
