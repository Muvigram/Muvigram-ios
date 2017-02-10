//
//  CameraViewControllerWithVideoPicker.swift
//  Muvigram
//
//  Created by 박정이 on 2017. 1. 10..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import Foundation
import CTAssetsPickerController
import MBProgressHUD

extension CameraViewController{
    
    //click Done Button
    func assetsPickerController(_ picker: CTAssetsPickerController!, didFinishPickingAssets assets: [Any]!) {

        print("\(assets.count)")
        
        videoInfo.videoCount = assets.count
        guard let videos = assets as? [PHAsset] else { return }
        videoInfo.videoList = videos
        
        if assets.count <= 5 {
            
            self.imagePicker.dismiss(animated: true, completion: nil)
            //self.dismiss(animated: true, completion: nil)
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
        
        for asset in videos {
            picker.deselect(asset)
        }
    }
    
    //최대 갯수 5개
    func assetsPickerController(_ picker: CTAssetsPickerController!, shouldSelect asset: PHAsset!) -> Bool {
        return (picker.selectedAssets.count < 5)
    }
    
    func assetsPickerController(_ picker: CTAssetsPickerController!, didSelect asset: PHAsset!) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: {(avAsset, _, _) in
            //print(avAsset)
            
            if avAsset == nil{
                
                DispatchQueue.main.async {
                    picker.deselect(asset)
                    //팝업 띄우기
                    let hud = MBProgressHUD.showAdded(to: picker.view, animated: true)
                    hud.mode = .text
                    hud.label.text = "not support icloud"
                    hud.removeFromSuperViewOnHide = true
                    hud.hide(animated: true, afterDelay: 1)
                }
                
            }
            
            guard let urlAsset = avAsset as? AVURLAsset else{
                return
            }
            let ext = urlAsset.url.pathExtension
            
            if ext.isEqual("mp4"){
                DispatchQueue.main.async {
                    picker.deselect(asset)
                    let hud = MBProgressHUD.showAdded(to: picker.view, animated: true)
                    hud.mode = .text
                    hud.label.text = "not support mp4"
                    hud.removeFromSuperViewOnHide = true
                    hud.hide(animated: true, afterDelay: 1)
                }
            }
            
            guard let track = avAsset?.tracks(withMediaType: AVMediaTypeVideo).first else{ return }
            let size = track.naturalSize.applying(track.preferredTransform)
            if fabs(size.width) > 2000 {
                DispatchQueue.main.async {
                    picker.deselect(asset)
                    let hud = MBProgressHUD.showAdded(to: picker.view, animated: true)
                    hud.mode = .text
                    hud.label.text = "not support 4K"
                    hud.removeFromSuperViewOnHide = true
                    hud.hide(animated: true, afterDelay: 1)
                }
            }
            print(CGSize(width: fabs(size.width), height: fabs(size.height)))
            
        })

        //picker.deselect(asset)
    }
    
    //비디오 선택 조건
    func assetsPickerController(_ picker: CTAssetsPickerController!, shouldEnable asset: PHAsset!) -> Bool {
        
        if(asset.mediaType == .video && asset.mediaSubtypes != .videoHighFrameRate){
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
