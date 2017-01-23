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
    public func getLastVideoThumbnail() -> Observable<UIImage> {
        return Observable<UIImage>.create{ observableOfUIImage in
            let lastVideoOptions = PHFetchOptions()
            lastVideoOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            lastVideoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            lastVideoOptions.fetchLimit = 1
            let lastVideoPHAsset = PHAsset.fetchAssets(with: lastVideoOptions).firstObject
            PHImageManager.default().requestImage(for: lastVideoPHAsset!, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: nil) { image, _ in
                if let image = image {
                    observableOfUIImage.on(Event.next(image))
                    observableOfUIImage.on(Event.completed)
                } else {
                    observableOfUIImage.on(Event.error(NSError(domain: "VIDEO IMAGE IS NIL", code: 404, userInfo: nil)))
                }
            }
            return Disposables.create()
        }
    }
    
    public func saveVideoWithURL(url: URL) -> Observable<Void> {
        return Observable<Void>.create{ observableOfVoid in
            if let videoData = NSData(contentsOf: url) {
                PHPhotoLibrary.shared().performChanges({
                    videoData.write(toFile: url.path, atomically: true);
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }, completionHandler: { success, error in
                    if success {
                        observableOfVoid.on(Event.completed)
                    } else {
                        observableOfVoid.on(Event.error(error!))
                    }
                })
            }
            return Disposables.create()
        }
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
    
    public func encodeVideofileForMargins(_ videoUrlArray: [URL], _ musicTimeStampArray: [CMTime], _ musicUrl: URL) -> Observable<URL> {
        
        return Observable<URL>.create{ observableOfUrl in
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
            
            // Compare the URL of the selected music file with the URL of the silent file and distinguish between 
            // the timing of recording without selecting music and the timing of not recording.
            let silenceMp3Path = Bundle.main.path(forResource: "Silence_15_sec", ofType: "mp3")
            
            
            for (idx, videoUrl) in videoUrlArray.enumerated() {
                let videoAsset = AVURLAsset(url: videoUrl)
                let tracks = videoAsset.tracks(withMediaType: AVMediaTypeVideo)
                let videoAudios = videoAsset.tracks(withMediaType: AVMediaTypeAudio)
                
                if tracks.count > 0 {
                    do {
                        
                        let duration = CMTime(seconds: CMTimeGetSeconds(musicTimeStampArray[idx+1]) - CMTimeGetSeconds(musicTimeStampArray[idx]), preferredTimescale: 2000000000)
                        
                        let assetTrackVedio = tracks.first!
                        try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration),
                                                       of: assetTrackVedio, at: insertTime)
                        
                        // When music is not selected, use the video tone.
                        if musicUrl.path != silenceMp3Path {
                            try trackAudio.insertTimeRange(CMTimeRangeMake(musicTimeStampArray[idx], duration),
                                                           of: assetTrackAudio, at: insertTime)
                        } else {
                            let assetTrackAudio = videoAudios.first!
                            try trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                                                           of: assetTrackAudio, at: insertTime)
                        }
                        
                        // 병합 시작 위치 갱신
                        insertTime = CMTimeAdd(insertTime, duration)
                    } catch {
                        print("mergeVideoFile insertTimeRange error")
                    }
                }
            }
            
            // 로고 추가
            do {
                let logoVideoUrl = Bundle.main.url(forResource: "logo_video", withExtension: "mov")
                
                if let logoVideoUrl = logoVideoUrl {
                    let logoAsset = AVURLAsset(url: logoVideoUrl)
                    let assetTrackLogoVedio = logoAsset.tracks(withMediaType: AVMediaTypeVideo).first!
                    
                    try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, logoAsset.duration),
                                                   of: assetTrackLogoVedio, at: insertTime)
                    
                }
            } catch {
                print("mergeVideoFile insertLogoVideo error")
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
                        observableOfUrl.on(Event.error(exportSession.error!))
                        break
                    default:
                        // 병합한 비디오파일을 쓰는 것에 성공하였다면 완료 호출
                        observableOfUrl.on(Event.next(combinedVideoUrl))
                        // 임시 파일 삭제
                        observableOfUrl.onCompleted()
                    }
                })
            }
            return Disposables.create()
        }
        
    }
}
