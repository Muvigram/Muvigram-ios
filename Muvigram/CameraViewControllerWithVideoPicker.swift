//
//  CameraViewControllerWithVideoPicker.swift
//  Muvigram
//
//  Created by 박정이 on 2017. 1. 10..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import Foundation
import CTAssetsPickerController

extension CameraViewController{
    
    //click Done Button
    func assetsPickerController(_ picker: CTAssetsPickerController!, didFinishPickingAssets assets: [Any]!) {
        print("done!!!!!!!!!")
        print("\(assets.count)")
        
        videoInfo.videoCount = assets.count
        guard let videos = assets as? [PHAsset] else { return }
        videoInfo.videoList = videos
        
        if assets.count <= 5 {
            self.dismiss(animated: true, completion: nil)
            let musicViewController = self.storyboard?.instantiateViewController(withIdentifier: "myMusic") as! MusicEditorViewController
            
            musicViewController.videosInfo = videoInfo
            present(musicViewController, animated: true, completion: nil)
        }
        
        let semaphore = DispatchSemaphore(value: 1)
        
        //내가 바로 쓰레드, 하나씩 들어온다. - 여기서 인덱스가 꼬이는 것 같다.
        func convertToURLAsset(_ avAsset: AVAsset?) {
            semaphore.wait()
            guard let urlAsset = avAsset as? AVURLAsset else{
                return
            }
            
            let localVideoUrl = urlAsset.url as NSURL
            print(localVideoUrl)
            
            let player = AVPlayer(url: localVideoUrl as URL)
            
            self.videoInfo.videoURL.append(localVideoUrl)
            self.videoInfo.playerList.append(player)
            
            print(self.videoInfo.videoURL.count)
            print(self.videoInfo.playerList.count)
            
            semaphore.signal()
        }
        
        //쓰레드 돌린다!
        for item in videos {
            PHImageManager.default().requestAVAsset(forVideo: item, options: nil, resultHandler: { (avAsset, _ , _) in
                convertToURLAsset(avAsset)
                if item.pixelWidth <= item.pixelHeight {
                    self.videoInfo.isVertical.append(true)
                }else{
                    self.videoInfo.isVertical.append(false)
                }
            })
        }
    }
    
    //최대 갯수 5개
    func assetsPickerController(_ picker: CTAssetsPickerController!, shouldSelect asset: PHAsset!) -> Bool {
        return (picker.selectedAssets.count < 5)
    }
    
    //비디오(3분내)만 선택 되게
    func assetsPickerController(_ picker: CTAssetsPickerController!, shouldEnable asset: PHAsset!) -> Bool {
        if(asset.mediaType == .video){
            let duration = asset.duration
            var isSatisfied = false
            if asset.pixelWidth * 9 == asset.pixelHeight * 16 || asset.pixelWidth * 16 == asset.pixelHeight * 9 {
                isSatisfied = true
            }
            return duration <= 3000 && isSatisfied
        }else{
            return false
        }
    }
}
