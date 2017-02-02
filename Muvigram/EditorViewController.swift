//
//  EditorViewController.swift
//  Muvigram
//
//  Created by 박정이 on 2017. 1. 10..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import ICGVideoTrimmer
import MediaPlayer
import MBProgressHUD

class EditorViewController: UIViewController, ICGVideoTrimmerDelegate, AVAudioPlayerDelegate,
UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    
    
    
    //model
    var videosInfo = VideosInfo()
    
    //player
    var player = AVPlayer()
    var resultPlayer = AVPlayer()
    var audioPlayer = AVPlayer()
    
    var playerLayer = AVPlayerLayer()
    //    let playButton = UIImageView(image: #imageLiteral(resourceName: "play_button"))
    
    //about Time..
    var startTime:CGFloat = 0.0
    var endTime:CGFloat = 0.0
    var videoPlayBackPosition:CGFloat = 0.0
    
    var playbackTimeCheckerTimer:Timer!
    
    //dynamic view
    var trimmerView = ICGVideoTrimmerView(frame: CGRect(x: 0, y: 0, width: 375, height: 86))
    var allocatedViews:[UIView] = []
    
    //etc.
    var index:Int = 0
    var isResultVideo:Bool = true
    var isResultVideoEnded:Bool = true
    var containedVideoCount = 0
    var bar:Int = 0
    var timeObservationToken:Any?
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var bottomLabelView: UIView!
    @IBOutlet weak var resultVideoView: UIView!
    
    //newwww
    
    var collectionView:UICollectionView!
    var buttonUIList:[UIView] = []
    
    let homeImageView = UIImageView(image: #imageLiteral(resourceName: "home.png"))
    let doneImageView = UIImageView(image: #imageLiteral(resourceName: "done.png"))
    let insertImageView = UIImageView(image: #imageLiteral(resourceName: "insert.png"))
    let cancelImageView = UIImageView(image: #imageLiteral(resourceName: "cancel.png"))
    let deleteButton = UIImageView(image: #imageLiteral(resourceName: "delete"))
    
    @IBOutlet weak var homeView: UIView!
    @IBOutlet weak var doneView: UIView!
    @IBOutlet weak var cancelView: UIView!
    @IBOutlet weak var insertView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    
    var playerLayerHorizontal = AVPlayerLayer()
    
    // gonini
    var musicInputTime: CMTime?
    var musicOutputTime: CMTime?
    var musicFileurl: URL?
    var dismissFunc: (() -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        warningLabel.isHidden = true
        warningLabel.isUserInteractionEnabled = true
        
        //버튼들 사이즈 조절
        homeImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        doneImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        insertImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        cancelImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        homeImageView.isUserInteractionEnabled = true
        doneImageView.isUserInteractionEnabled = true
        insertImageView.isUserInteractionEnabled = true
        cancelImageView.isUserInteractionEnabled = true
        
        //재생버튼 붙임 - resultVideo가 없더라도 audio play 하기 위함
        //        playButton.frame = CGRect(x: 126, y: 122, width: 123, height: 123)
        //        videoView.addSubview(playButton)
        //        playButton.isHidden = false
        
        //우선은 resultVideo 에 focus,
        //index - 0 인 currentVideo 보여줌
        isResultVideo = true
        
        allocateButtons()
        addHomeAndDoneButton()
        playSound()
        
        
        //-------------------  observer func. ---------------------
        let gestureInsert = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.touchInsertBtnAction(_:)))
        insertImageView.addGestureRecognizer(gestureInsert)
        
        let gestureCancel = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.touchCancelBtnAction(_:)))
        cancelImageView.addGestureRecognizer(gestureCancel)
        
        let gestureDelete = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.deleteVideoAction(_:)))
        resultVideoView.addGestureRecognizer(gestureDelete)
        
        let gestureHome = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.goHomeAction(_:)))
        homeImageView.addGestureRecognizer(gestureHome)
        
        let gestureDone = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.doneAction(_:)))
        doneImageView.addGestureRecognizer(gestureDone)
        
        //재생 일시정지
        let gestureVideoTouch = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.touchVideoAction(_:)))
        videoView.addGestureRecognizer(gestureVideoTouch)
        
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var currentPlayerLayer = AVPlayerLayer()
    
    func addHomeAndDoneButton(){
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        stopPlayBackTimeChecker()
        
        homeView.addSubview(homeImageView)
        doneView.addSubview(doneImageView)
        
        insertImageView.removeFromSuperview()
        cancelImageView.removeFromSuperview()
        
        playerLayer.removeFromSuperlayer()
        isResultVideoEnded = false
        isResultVideo = true
        
        count = 0
        
        //첫번째 영상 붙이기, 만약에 가로 동영상이면 세로로!
        if containedVideoCount > 0 {
            playerLayerList[0].player!.seek(to: self.videosInfo.range[0].start)
            playerLayerList[0].player!.pause()
            
            videoView.layer.addSublayer(playerLayerList[0])
            
            audioPlayer.seek(to: musicInputTime!)
            currentPlayerLayer = playerLayerList[0]
        }
    }
    
    func addInsertAndCancelButton(){
        insertView.addSubview(insertImageView)
        cancelView.addSubview(cancelImageView)
        
        homeImageView.removeFromSuperview()
        doneImageView.removeFromSuperview()
        
        isResultVideo = false
    }
    
    //선택한 동영상 갯수 별 하단 탭의 갯수 할당
    func allocateButtons(){
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5)
        layout.itemSize = CGSize(width: 50, height: 50)
        collectionView = UICollectionView(frame: videoView.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = UIColor(white: 1, alpha: 0)
        bottomLabelView.addSubview(collectionView)
        
        for i in 1...videosInfo.videoCount {
            let ui:UIImageView = UIImageView(image: #imageLiteral(resourceName: "button_background.png"))
            ui.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            ui.contentMode = .scaleAspectFit
            let tempButton:UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            tempButton.setTitle("\(i)", for: .normal)
            tempButton.titleLabel!.font = UIFont(name: "Open Sans Semibold Italic", size: 50)
            ui.addSubview(tempButton)
            
            UIGraphicsBeginImageContext(ui.bounds.size)
            ui.layer.render(in: UIGraphicsGetCurrentContext()!)
            let finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            tempButton.removeFromSuperview()
            ui.image = finalImage
            
            buttonUIList.append(ui)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videosInfo.videoCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.addSubview(buttonUIList[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let totalCellWidth = 50 * videosInfo.videoCount
        let totalSpacingWidth = 10 * (videosInfo.videoCount - 1)
        
        let leftInset = (bottomLabelView.frame.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2;
        let rightInset = leftInset
        
        return UIEdgeInsetsMake(10, leftInset, 10, rightInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //resultPlayer initialize
        if containedVideoCount > 0 {
            currentPlayerLayer.player!.seek(to: self.videosInfo.range[0].start)
            currentPlayerLayer.player!.pause()
            
            audioPlayer.pause()
            timer.invalidate()
            resultTimer.invalidate()
            
            self.progressBar.removeFromSuperview()
            self.width = 0
        }
        
        playerLayer.removeFromSuperlayer()
        attachThumbnailProgressBar(indexPath.row)
        addInsertAndCancelButton()
    }
    
    
    //썸네일 붙이기
    func attachThumbnailProgressBar(_ index:Int){
        
        //커런트 비디오 띄우기
        self.index = index
        isResultVideo = false
        count = 0
        
        player = videosInfo.playerList[index]
        playerLayer.player = player
        
        
        //가로 동영상 세로로 회전
        playerLayer.setAffineTransform(CGAffineTransform.identity)
        if videosInfo.isVertical[index] == false {
            playerLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 2))
        }
        playerLayer.frame = videoView.bounds
        playerLayer.removeAllAnimations()
        videoView.layer.addSublayer(playerLayer)
        
        //플레이버튼
        //        playButton.frame = CGRect(x: 126, y: 122, width: 123, height: 123)
        //        videoView.addSubview(playButton)
        //        playButton.isHidden = false
        
        //썸네일 붙이기
        trimmerView.asset = AVAsset(url: videosInfo.videoURL[index] as URL)
        trimmerView.delegate = self
        trimmerView.trackerColor = UIColor.darkGray
        trimmerView.themeColor = UIColor(red:1.00, green:0.68, blue:0.29, alpha:1.0)
        trimmerView.minLength = 1.0
        trimmerView.maxLength = 15-stackedTime // ->남은초로 바꿔주기
        trimmerView.frame = bottomLabelView.bounds
        trimmerView.resetSubviews()
        
        bottomLabelView.addSubview(trimmerView)
        
        
        //current video 끝날시
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(note:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        
    }
    
    
    var count = 0
    var width = 0.0
    var timer = Timer()
    var resultTimer = Timer()
    var audioToken:Any?
    
    //재생, 일시정지
    func touchVideoAction(_ sender:UITapGestureRecognizer){
        
        //리절트 비디오 재생
        if isResultVideo && containedVideoCount>0 {
            if audioPlayer.timeControlStatus == .playing {
                
                print("멈춤")
                audioPlayer.pause()
                currentPlayerLayer.player!.pause()
                resultTimer.invalidate()
                if let timetoken = audioToken {
                    audioPlayer.removeTimeObserver(timetoken)
                    audioToken = nil
                }
                
            }else if audioPlayer.timeControlStatus != .playing {
                
                print("시작")
                audioPlayer.play()
                //playButton.isHidden = true
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.makeProgressBar), userInfo: nil, repeats: true)
                
                currentPlayerLayer.player!.play()
                
                resultTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.playResult), userInfo: nil, repeats: true)
                
                //오디오 언제 끝나는지 감시
                //                audioToken = audioPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 10), queue: DispatchQueue.main, using: { (CMTime) in
                //                    print("audio time \(self.audioPlayer.currentTime().value)")
                //                    print("outpu time \(self.musicOutputTime!.value)")
                //                    if self.audioPlayer.currentTime() >= self.musicOutputTime! {
                //                        self.resultTimer.invalidate()
                //                        print("오디오 끝!")
                //
                //                        self.currentPlayerLayer.player?.pause()
                //                        self.currentPlayerLayer.removeFromSuperlayer()
                //                        print("지웠따")
                //                        self.isResultVideoEnded = true
                //
                //                        if let timetoken = self.audioToken {
                //                            self.audioPlayer.removeTimeObserver(timetoken)
                //                            self.audioToken = nil
                //                        }
                //
                //
                //                        //요기
                //                        if self.isResultVideo {
                //
                //                            if self.isResultVideoEnded {
                //                                self.currentPlayerLayer = self.playerLayerList[0]
                //                                self.currentPlayerLayer.player!.seek(to: self.videosInfo.range[0].start)
                //                                self.currentPlayerLayer.player!.pause()
                //                                self.count = 0
                //
                //                                self.videoView.layer.addSublayer(self.currentPlayerLayer)
                //
                //                            }else {
                //
                //                            }
                //
                ////                            self.videoView.addSubview(self.playButton)
                ////                            self.playButton.isHidden = false
                //
                //                            self.audioPlayer.seek(to: self.musicInputTime!)
                //                            self.audioPlayer.pause()
                //                        }
                //
                //                        //progress bar
                //                        self.progressBar.removeFromSuperview()
                //                        self.width = 0
                //
                //                        self.isResultVideoEnded = false
                //
                //                    }
                //                })
                
            }
            //커렌트 비디오 재생
        }else if isResultVideo == false{
            if player.timeControlStatus == .playing {
                player.pause()
                audioPlayer.pause()
                stopPlayBackTimeChecker()
                
            }else if player.timeControlStatus == .paused {
                player.seek(to: CMTimeMakeWithSeconds(Float64(startTime), 1000000000))
                player.play()
                audioPlayer.seek(to: musicInputTime! + CMTimeMakeWithSeconds(Float64(stackedTime), 1000000000))
                audioPlayer.play()
                startPlaybackTimeChecker()
            }
        }
    }
    
    
    
    func playResult(){
        
        var tempPlayerlayer = AVPlayerLayer()
        
        print("enddd time \(soundEndList[count].value)")
        if count == containedVideoCount-1 {
            tempPlayerlayer = AVPlayerLayer(layer: playerLayerList[0])
            //tempPlayerlayer = playerLayerList[0]
            //tempPlayerlayer.player!.seek(to: self.videosInfo.range[0].start)
            //tempPlayerlayer.player!.pause()
        }else{
            playerLayerList[count+1].player!.seek(to: self.videosInfo.range[self.count+1].start)
            //tempPlayerlayer = AVPlayerLayer(layer: playerLayerList[count+1])
            //tempPlayerlayer = playerLayerList[count+1]
            //tempPlayerlayer.player!.seek(to: self.videosInfo.range[self.count+1].start)
        }
        
        if audioPlayer.currentTime() >= soundEndList[count] {
            
            currentPlayerLayer.player!.pause()
            currentPlayerLayer.removeFromSuperlayer()
            print("지웠따")
            
            if self.count == self.containedVideoCount-1 {
                
                currentPlayerLayer = playerLayerList[0]
                //currentPlayerLayer = tempPlayerlayer
                //currentPlayerLayer = AVPlayerLayer(layer: tempPlayerlayer)
                currentPlayerLayer.player!.seek(to: self.videosInfo.range[0].start)
                
                self.videoView.layer.addSublayer(self.currentPlayerLayer)
                
                
                audioPlayer.seek(to: musicInputTime!)
                audioPlayer.pause()
                self.count = 0
                
                resultTimer.invalidate()
                self.progressBar.removeFromSuperview()
                self.width = 0
                
            }else {
                
                count = count + 1
                print(count)
                
                //currentPlayerLayer = tempPlayerlayer
                //currentPlayerLayer = AVPlayerLayer(layer: tempPlayerlayer)
                currentPlayerLayer = playerLayerList[count]
                //currentPlayerLayer.player!.seek(to: self.videosInfo.range[self.count].start)
                
                currentPlayerLayer.player!.play()
                self.videoView.layer.addSublayer(currentPlayerLayer)
                
            }
        }
        
    }
    
    var progressBar = UIView()
    
    //프로그래스 바 만들기
    func makeProgressBar(){
        
        if audioPlayer.timeControlStatus != .playing{
            timer.invalidate()
            
        }else{
            self.width += 2.5
            progressBar.removeFromSuperview()
            progressBar = UIView(frame: CGRect(x: 0, y: 0, width: self.width, height: Double(resultVideoView.frame.height)))
            progressBar.backgroundColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.5)
            self.resultVideoView.addSubview(progressBar)
        }
    }
    
    //음악 재생
    func playSound(){
        audioPlayer = AVPlayer(url: musicFileurl!)
    }
    
    var temp:Int = 0
    var stackedTime:CGFloat = 0.0
    var durationList:[CGFloat] = []
    var playerLayerList:[AVPlayerLayer] = []
    var soundStartList:[CMTime] = []
    var soundEndList:[CMTime] = []
    var barList:[Int] = []
    
    var finalURLList:[URL] = []
    var finalMusicTimeStamp:[CMTime] = []
    
    //인서트 버튼 눌렀을 때
    func touchInsertBtnAction(_ sender:UITapGestureRecognizer){
        
        //비디오에 대한 정보
        let startFloat = Float64(startTime)
        let endFloat = Float64(endTime)
        let duration = endFloat - startFloat
        
        let startCMTime = CMTimeMakeWithSeconds(startFloat, 1000000000)
        let endCMTime = CMTimeMakeWithSeconds(endFloat, 1000000000)
        let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
        
        //현재 진행중인 플레이어 stop
        player.pause()
        playerLayer.removeFromSuperlayer()
        audioPlayer.pause()
        audioPlayer.seek(to: musicInputTime!)
        
        containedVideoCount += 1
        
        videosInfo.order.append(self.index)
        videosInfo.range.append(timeRange)
        finalURLList.append(videosInfo.videoURL[index] as URL)
        
        print(videosInfo.order)
        print(videosInfo.range)
        
        trimmerView.removeFromSuperview()
        
        //얼로케이티드 바 할당
        bar = Int(duration * Float64(375)/Float64(15))
        let allocatedView = UIView(frame: CGRect(x: temp, y: 0, width: bar, height: Int(resultVideoView.frame.height)))
        
        print("index : \(index)")
        
        allocatedView.backgroundColor = UIColor(red:1.00, green:0.33, blue:0.42, alpha:1.0)
        allocatedView.layer.borderWidth = 1
        allocatedView.layer.borderColor = UIColor.white.cgColor
        
        deleteButton.removeFromSuperview()
        deleteButton.frame = CGRect(x: allocatedView.frame.width-20, y: 5, width: 15, height: 15)
        allocatedView.addSubview(deleteButton)
        
        allocatedViews.append(allocatedView)
        print("num of allocatedView \(allocatedViews.count)")
        resultVideoView.addSubview(allocatedView)
        temp = temp + bar
        barList.append(bar)
        
        //playerLayer 생성
        let tempPlayerLayer = AVPlayerLayer(player: videosInfo.playerList[index])
        tempPlayerLayer.player = videosInfo.playerList[index]
        if videosInfo.isVertical[index] == false {
            tempPlayerLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 2))
        }
        tempPlayerLayer.frame = self.videoView.bounds
        tempPlayerLayer.removeAllAnimations()
        playerLayerList.append(tempPlayerLayer)
        
        //음악에 맞게 초 입력
        soundStartList.append(musicInputTime! + CMTimeMakeWithSeconds(Float64(stackedTime), 1000000000))
        print("stackedTIme \(stackedTime)")
        
        //남은 초 표시
        stackedTime += self.endTime - self.startTime
        durationList.append(self.endTime - self.startTime)
        if stackedTime > 14 {
            warningLabel.isHidden = false
        }else{
            //            trimmerView.stackedTime = stackedTime
        }
        
        //음악에 맞게 초 입력
        soundEndList.append(musicInputTime! + CMTimeMakeWithSeconds(Float64(stackedTime), 1000000000))
        print("stackedTIme \(stackedTime)")
        
        addHomeAndDoneButton()
        
        
        //팝업 띄우기
        let hud = MBProgressHUD.showAdded(to: videoView, animated: true)
        hud.mode = .text
        hud.label.text = "inserted!"
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: true, afterDelay: 2)
    }
    
    //캔슬 버튼 눌렀을 때
    func touchCancelBtnAction(_ sender:UITapGestureRecognizer){
        player.pause()
        playerLayer.removeFromSuperlayer()
        audioPlayer.pause()
        audioPlayer.seek(to: musicInputTime!)
        
        addHomeAndDoneButton()
        trimmerView.removeFromSuperview()
        print("cancel")
    }
    
    //삭제 기능
    func deleteVideoAction(_ sender:UITapGestureRecognizer){
        
        isResultVideoEnded = false
        count = 0
        
        //프로그레스바 initialize
        progressBar.removeFromSuperview()
        width = 0
        
        
        //오디오 initialize
        audioPlayer.seek(to: musicInputTime!)
        audioPlayer.pause()
        
        
        if videosInfo.order.count > 0 {
            
            //video initialize
            currentPlayerLayer.player!.pause()
            currentPlayerLayer.removeFromSuperlayer()
            //time reset
            stackedTime = stackedTime - durationList.popLast()!
            
            //영상이 하나뿐 이지 않을때 = 지워지면 남는영상이 있을 때
            if videosInfo.order.count != 1 {
                currentPlayerLayer = playerLayerList[0]
                currentPlayerLayer.player!.seek(to: videosInfo.range[0].start)
                currentPlayerLayer.player!.pause()
                videoView.layer.addSublayer(currentPlayerLayer)
            }
            
            //삭제
            containedVideoCount -= 1
            
            print(videosInfo.order)
            print(videosInfo.range)
            print(allocatedViews)
            
            videosInfo.order.removeLast()
            videosInfo.range.removeLast()
            playerLayerList.removeLast()
            soundEndList.removeLast()
            soundStartList.removeLast()
            finalURLList.removeLast()
            
            allocatedViews.popLast()?.removeFromSuperview()
            temp = temp - barList.popLast()!
            
            if videosInfo.order.count > 0 {
                deleteButton.frame = CGRect(x: allocatedViews.last!.frame.width-20, y: 5, width: 15, height: 15)
                allocatedViews.last!.addSubview(deleteButton)
            }
            
            
            print(videosInfo.order)
            print(videosInfo.range)
            print(allocatedViews)
            
            warningLabel.isHidden = true
            
        }else{
            
            //비디오 없을때 팝업 뜨게
            let hud = MBProgressHUD.showAdded(to: videoView, animated: true)
            hud.mode = .text
            hud.label.text = "no video to delete"
            hud.removeFromSuperViewOnHide = true
            hud.hide(animated: true, afterDelay: 2)
            
        }
        
        if videosInfo.order.count == 0 {
            temp = 0
        }
        
        print("contained video : \(containedVideoCount)")
        resultTimer.invalidate()
        
    }
    
    
    //홈으로
    func goHomeAction(_ sender:UITapGestureRecognizer){
        let alert = UIAlertController(title: "Alert", message: "wanna go home?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: false) {
                self.deinitVideoInfo()
                self.dismissFunc!()
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func deinitVideoInfo(){
        videosInfo.isVertical.removeAll()
        videosInfo.order.removeAll()
        videosInfo.playerList.removeAll()
        videosInfo.range.removeAll()
        videosInfo.videoCount = 0
        videosInfo.videoList.removeAll()
        videosInfo.videoURL.removeAll()
    }
    
    //다했따아
    func doneAction(_ sender:UITapGestureRecognizer){
        
        if containedVideoCount > 0 {
            finalMusicTimeStamp = soundStartList
            finalMusicTimeStamp.append(soundEndList.last!)
            videoEditingFinalized(videoUrlArray: finalURLList, musicTimeStampArray: finalMusicTimeStamp, musicUrl: musicFileurl!)
        }
    }
    
    
    func startPlaybackTimeChecker(){
        stopPlayBackTimeChecker()
        self.playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                             selector: #selector(self.onPlaybackTimeCheckerTimer), userInfo: nil, repeats: true)
    }
    
    func stopPlayBackTimeChecker(){
        if (playbackTimeCheckerTimer != nil) {
            playbackTimeCheckerTimer.invalidate()
            playbackTimeCheckerTimer = nil
        }
    }
    
    func onPlaybackTimeCheckerTimer(){
        videoPlayBackPosition = CGFloat(CMTimeGetSeconds(player.currentTime()))
        trimmerView.seek(toTime: CGFloat(CMTimeGetSeconds(player.currentTime())))
        
        if(videoPlayBackPosition >= endTime){
            videoPlayBackPosition = startTime
            seekVideoToPos(pos: startTime)
            trimmerView.seek(toTime: startTime)
        }
    }
    
    func seekVideoToPos(pos:CGFloat){
        videoPlayBackPosition = pos
        let time = CMTimeMakeWithSeconds(Float64(videoPlayBackPosition), player.currentTime().timescale)
        player.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        audioPlayer.seek(to: musicInputTime! + CMTimeMakeWithSeconds(Float64(stackedTime), player.currentTime().timescale))
    }
    
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        
        let numberOfPlaces = 1.0
        let multiplier:CGFloat = pow(10.0, CGFloat(numberOfPlaces))
        
        self.startTime = round(startTime * multiplier)/multiplier
        self.endTime = round(endTime * multiplier)/multiplier
        
        print("\(self.startTime) :  \(self.endTime)")
        print(Float64(self.startTime))
        
        player.seek(to: CMTimeMakeWithSeconds(Float64(self.startTime), 1000000000))
        
        //처음에는 음악 들려야함
        if trimmerView.isGestureEnd && startTime >= 0{
            self.player.play()
            self.audioPlayer.seek(to: musicInputTime! + CMTimeMakeWithSeconds(Float64(stackedTime), 1000000000))
            self.audioPlayer.play()
            self.startPlaybackTimeChecker()
        }
    }
    
    //gesture에 따라 음악 들리고 안들리고
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, isGestureEnd end: Bool) {
        if end == true {
            self.player.play()
            self.audioPlayer.seek(to: musicInputTime! + CMTimeMakeWithSeconds(Float64(stackedTime), 1000000000))
            self.audioPlayer.play()
            self.startPlaybackTimeChecker()
        }else{
            player.pause()
            audioPlayer.pause()
        }
    }
    
    
    func playerDidFinishPlaying(note: Notification){
        player.seek(to: CMTimeMakeWithSeconds(Float64(self.startTime), 1000000000))
        self.player.play()
        self.audioPlayer.seek(to: musicInputTime!+CMTimeMakeWithSeconds(Float64(stackedTime), 1000000000))
        self.audioPlayer.play()
        startPlaybackTimeChecker()
    }
    // 비디오 편집 완료 -> 공유화면 이동
    // @videoUrlArray 병합할 비디오의 urlArray
    // @musicTimeStampArray 병합할 음악의 TimeStampArray
    // @musicUrl -> 병합할 음악의 url
    // 비디오가 n개일 경우 병합할 음악의 TimeStamp는 n + 1 개 입니다.
    func videoEditingFinalized(videoUrlArray: [URL], musicTimeStampArray: [CMTime], musicUrl: URL) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let shardViewController = appDelegate.newShareViewControllerInstance()
        shardViewController.videoUrlArray = videoUrlArray
        shardViewController.musicTimeStampArray = musicTimeStampArray
        shardViewController.musicUrl = musicUrl
        self.present(shardViewController, animated: true, completion: nil)
    }
}
