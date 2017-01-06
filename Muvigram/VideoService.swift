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
        
        let subject = PublishSubject<UIImage>()
        
        let lastVideoOptions = PHFetchOptions()
        
        lastVideoOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        lastVideoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        lastVideoOptions.fetchLimit = 1
        let lastVideoPHAsset = PHAsset.fetchAssets(with: lastVideoOptions).firstObject
        
        PHImageManager.default().requestImage(for: lastVideoPHAsset!, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: nil) { image, _ in
            if let image = image {
                subject.onNext(image)
            } else {
                subject.onError(NSError(domain: "VIDEO IMAGE IS NIL", code: 404, userInfo: nil))
            }
        }
        return subject
    }
    
    public func saveVideoWithURL(url: URL) -> PublishSubject<Void> {
        let subject = PublishSubject<Void>()
        if let videoData = NSData(contentsOf: url) {
            PHPhotoLibrary.shared().performChanges({
                videoData.write(toFile: url.path, atomically: true);
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: { success, error in
                if success {
                    subject.onCompleted()
                } else {
                    subject.onError(error!)
                }
            })
        }
        return subject
    }
    
    public func clearUnnecessaryfilesForMusicAndVideo(_ videoUrlArray: inout [URL], _ musicTimeStampArray: inout [CMTime])  {
        
     
        
        for url in videoUrlArray {
            removeVideoWithPath(atPath: url.path)
        }
        videoUrlArray.removeAll()
        musicTimeStampArray.removeAll()
    }
    
    public func removeVideoWithPath(atPath path: String) {
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            }
            catch {
                print("Could not remove file at path: \(path)")
            }
        }
    }
    
    public func deleteVideofilesTemporary(_ videoUrlArray: inout [URL], _ musicTimeStampArray: inout [CMTime], _ player: inout AVPlayer) {
        guard !videoUrlArray.isEmpty else {
            return
        }
        let stackTopFilePath = videoUrlArray.popLast()?.path
        removeVideoWithPath(atPath: stackTopFilePath!)
        // Changes the stack bar to the time of the previously recorded video.
        _ = musicTimeStampArray.popLast()
        if let lastTime = musicTimeStampArray.last, musicTimeStampArray.count >= 2 {
            player.seek(to: lastTime)
        } else {
            _ = musicTimeStampArray.popLast()
        }
    }
    
    public func encodeVideofileForMargins(_ videoUrlArray: inout [URL], _ musicTimeStampArray: inout [CMTime], _ musicUrl: URL) -> PublishSubject<URL> {
        let subject = PublishSubject<URL>()
        
        let compostion = AVMutableComposition()
        let trackVideo: AVMutableCompositionTrack
            = compostion.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let trackAudio: AVMutableCompositionTrack
            = compostion.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        var insertTime = kCMTimeZero
        
        trackVideo.preferredTransform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2));
        
        let audeoAsset = AVURLAsset(url: musicUrl)
        let audios = audeoAsset.tracks(withMediaType: AVMediaTypeAudio)
        let assetTrackAudio = audios.first!
        
        for (idx, videoUrl) in videoUrlArray.enumerated() {
            let videoAsset = AVURLAsset(url: videoUrl)
            let tracks = videoAsset.tracks(withMediaType: AVMediaTypeVideo)
            
            if tracks.count > 0 {
                do {
                    
                    let duration = CMTime(seconds: CMTimeGetSeconds(musicTimeStampArray[idx+1]) - CMTimeGetSeconds(musicTimeStampArray[idx]), preferredTimescale: 2000000000)
                    
                    let assetTrackVedio = tracks.first!
                    try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration),
                                                   of: assetTrackVedio, at: insertTime)
                    
                    try trackAudio.insertTimeRange(CMTimeRangeMake(musicTimeStampArray[idx], duration),
                                                   of: assetTrackAudio, at: insertTime)
                    
                    print("idx -> \(idx)")
                    print("music time ->   #1       \(CMTimeGetSeconds(duration))")
                    print("video time ->   #3       \(CMTimeGetSeconds(duration))")
                    
                    // 병합 시작 위치 갱신
                    insertTime = CMTimeAdd(insertTime, duration)
                } catch {
                    print("mergeVideoFile insertTimeRange error")
                }
            }
        }
        
        // 병합한 비디오가 쓰여질 경로 지정
        let combinedVideoName = UUID().uuidString
        let combinedVideoFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((combinedVideoName as NSString).appendingPathExtension("mov")!)
        let combinedVideoUrl = URL(fileURLWithPath: combinedVideoFilePath)
        
        // 병합한 비디오 쓰기
        if let exportSession = AVAssetExportSession(asset: compostion, presetName: AVAssetExportPresetHighestQuality){
            
            exportSession.outputURL = combinedVideoUrl
            exportSession.outputFileType = AVFileTypeMPEG4
            exportSession.exportAsynchronously(completionHandler: {
                switch exportSession.status {
                case .failed, .cancelled:
                    subject.onError(exportSession.error!)
                    break
                default:
                    // 병합한 비디오파일을 쓰는 것에 성공하였다면 완료 호출
                    subject.onNext(combinedVideoUrl)
                    subject.onCompleted()
                    // 임시 파일 삭제
                    //self.cleanVideoandMusicStack()
                }
            })
        }
        return subject
    }
}
