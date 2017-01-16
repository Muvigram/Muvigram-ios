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

class EditorViewController: UIViewController, ICGVideoTrimmerDelegate, AVAudioPlayerDelegate,
                            UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{

    //model
    var videosInfo = VideosInfo()
    
    //player
    var player = AVPlayer()
    var resultPlayer = AVPlayer()
    var audioPlayer = AVAudioPlayer()
    
    var playerLayer = AVPlayerLayer()
    let playButton = UIImageView(image: #imageLiteral(resourceName: "play_button"))
    
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
    @IBOutlet weak var timeControlView: UILabel!
    
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        warningLabel.isHidden = true;
        
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
        playButton.frame = CGRect(x: 126, y: 122, width: 123, height: 123)
        videoView.addSubview(playButton)
        playButton.isHidden = false
        
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
        homeImageView.addGestureRecognizer(gestureDelete)
        
        //재생 일시정지
        let gestureVideoTouch = UITapGestureRecognizer(target: self, action: #selector(EditorViewController.touchVideoAction(_:)))
        videoView.addGestureRecognizer(gestureVideoTouch)
        
    }
    
    func addHomeAndDoneButton(){
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
            
            resultPlayer = videosInfo.playerList[videosInfo.order[0]]
            resultPlayer.seek(to: self.videosInfo.range[0].start)
            resultPlayer.pause()
            
            playerLayer.player = resultPlayer
            
            playerLayer.setAffineTransform(CGAffineTransform.identity)
            if videosInfo.isVertical[0] == false {
                playerLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 2))
            }
            
            
            playerLayer.frame = videoView.bounds
            playerLayer.removeAllAnimations()
            videoView.layer.addSublayer(playerLayer)
            
            audioPlayer.currentTime = TimeInterval(0)
        }
    }
    
    func addInsertAndCancelButton(){
        insertView.addSubview(insertImageView)
        cancelView.addSubview(cancelImageView)
        
        homeImageView.removeFromSuperview()
        doneImageView.removeFromSuperview()
        
        isResultVideo = false
    }
    
    //오디오가 끝나면? - resultVideo 에는 아무것도 없는데 audio playing 끝날시.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        if isResultVideo {
            videoView.addSubview(playButton)
            playButton.isHidden = false
        }
        
        //progress bar
        self.progressBar.removeFromSuperview()
        self.width = 0
        
        self.isResultVideoEnded = false
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
            resultPlayer.seek(to: self.videosInfo.range[0].start)
            resultPlayer.pause()
            
            audioPlayer.pause()
            timer.invalidate()
            
            //progress bar initialize
            if let token = timeObservationToken {
                resultPlayer.removeTimeObserver(token)
                timeObservationToken = nil
            }
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
        playButton.frame = CGRect(x: 126, y: 122, width: 123, height: 123)
        videoView.addSubview(playButton)
        playButton.isHidden = false
        
        //썸네일 붙이기
        trimmerView.asset = AVAsset(url: videosInfo.videoURL[index] as URL)
        trimmerView.delegate = self
        trimmerView.trackerColor = UIColor.darkGray
        trimmerView.themeColor = UIColor(red:1.00, green:0.68, blue:0.29, alpha:1.0)
        trimmerView.minLength = 1.0
        trimmerView.maxLength = 15 // ->남은초로 바꿔주기
        trimmerView.frame = bottomLabelView.bounds
        trimmerView.resetSubviews()
        
        bottomLabelView.addSubview(trimmerView)
        
//        //progress bar
//        if let token = timeObservationToken {
//            resultPlayer.removeTimeObserver(token)
//            timeObservationToken = nil
//        }
//        self.progressBar.removeFromSuperview()
//        self.width = 0
        
        //current video 끝날시
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(note:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        
    }

    
    var count = 0
    var width = 0.0
    var timer = Timer()
    
    //재생, 일시정지
    func touchVideoAction(_ sender:UITapGestureRecognizer){
        
        //리절트 비디오 재생
        if isResultVideo && containedVideoCount>0 {
            if audioPlayer.isPlaying {
                
                audioPlayer.pause()
                playButton.isHidden = false
                resultPlayer.pause()
                
            }else if audioPlayer.isPlaying == false {
                
                audioPlayer.play()
                playButton.isHidden = true
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.makeProgressBar), userInfo: nil, repeats: true)
                print(isResultVideoEnded)
                
                if isResultVideoEnded == false {
                    resultPlayer.play()
                    //리절트 비디오 다음 아이템 이어서 재생하기 - 여기서 느려진다, 쓰레드가 여러개 생겨서? - sync문제
                    timeObservationToken = resultPlayer.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, 100), queue: DispatchQueue.main, using: {(CMTime) -> Void in
                        
                        print(self.resultPlayer.currentTime())
                        
                        var tempItem = AVPlayerItem(url: self.videosInfo.videoURL[self.videosInfo.order[0]] as URL)
                        if self.count != self.containedVideoCount - 1 {
                            tempItem = AVPlayerItem(url: self.videosInfo.videoURL[self.videosInfo.order[self.count+1]] as URL)
                        }
                        
                        if self.resultPlayer.currentTime() >= self.videosInfo.range[self.count].end{
                            
                            self.playerLayer.removeFromSuperlayer()
                            self.playerLayer.setAffineTransform(CGAffineTransform.identity)
                            self.resultPlayer.replaceCurrentItem(with: tempItem)
                            
                            if self.count == self.containedVideoCount - 1{
                                
                                //self.resultPlayer.replaceCurrentItem(with: tempItem)
                                self.resultPlayer.seek(to: self.videosInfo.range[0].start)
                                self.resultPlayer.pause()
                                self.count = 0
                                
                                //self.playerLayer.removeFromSuperlayer()
                                //self.playerLayer.setAffineTransform(CGAffineTransform.identity)
                                if self.videosInfo.isVertical[self.videosInfo.order[self.count]] == false {
                                    self.playerLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 2))
                                }
                                self.playerLayer.frame = self.videoView.bounds
                                self.playerLayer.removeAllAnimations()
                                self.videoView.layer.addSublayer(self.playerLayer)
                                
                                print("마지막입니다요~")
                                if self.stackedTime <= 14 {
                                    self.isResultVideoEnded = true
                                }else{
                                    self.isResultVideoEnded = false
                                }
                                
                            }else {
                                self.count = self.count + 1
                                
                                
                                //self.playerLayer.removeFromSuperlayer()
                                //self.playerLayer.setAffineTransform(CGAffineTransform.identity)
                                if self.videosInfo.isVertical[self.videosInfo.order[self.count]] == false {
                                    self.playerLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 2))
                                }
                                self.playerLayer.frame = self.videoView.bounds
                                self.playerLayer.removeAllAnimations()
                                self.videoView.layer.addSublayer(self.playerLayer)
                                
                                
                                
                                
                                //self.resultPlayer.replaceCurrentItem(with: tempItem)
                                self.resultPlayer.seek(to: self.videosInfo.range[self.count].start)
                                
                                //self.playerLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform.identity)
                                //if self.videosInfo.isVertical[self.videosInfo.order[self.count]] == false {
                                //    self.playerLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi / 2))
                                //}
                                
                                
                                
                                
                                
                                
                                self.resultPlayer.play()
                                print("다음걸로 넘어갈게요~")
                            }
                        }
                    })
                }
                
            }
            //커렌트 비디오 재생
        }else if isResultVideo == false{
            if player.timeControlStatus == .playing {
                player.pause()
                audioPlayer.pause()
                playButton.isHidden = false
                stopPlayBackTimeChecker()
                
                
            }else if player.timeControlStatus == .paused {
                // TODO -- 여기서 문제가 생기는거 같습니당
                player.seek(to: CMTimeMakeWithSeconds(Float64(startTime), 1))
                player.play()
                audioPlayer.currentTime = TimeInterval(stackedTime)
                audioPlayer.play()
                playButton.isHidden = true
                startPlaybackTimeChecker()
                
                //current video play 끝나면 정지
                player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, 10), queue: DispatchQueue.main, using: {(CMTime) -> Void in
                    if self.player.currentTime() >= CMTimeMakeWithSeconds(Float64(self.endTime), self.player.currentTime().timescale){
                        self.player.seek(to: kCMTimeZero)
                        self.player.pause()
                        self.audioPlayer.currentTime = TimeInterval(self.stackedTime)
                        self.audioPlayer.pause()
                    }
                })
            }
        }
    }
    
    var progressBar = UIView()
    
    //프로그래스 바 만들기
    func makeProgressBar(){
        
        if audioPlayer.isPlaying == false{
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
        print("음악 큐!")
        let url = Bundle.main.url(forResource: "audio", withExtension:"mp3")!
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.delegate = self
            audioPlayer.setVolume(50, fadeDuration: 0)
            audioPlayer.prepareToPlay()
        } catch _ {
            print("그런 노래 없어요.(정색)")
        }
    }
    
    var temp:Int = 0
    var stackedTime:CGFloat = 0.0
    var durationList:[CGFloat] = []
    
    //인서트 버튼 눌렀을 때
    func touchInsertBtnAction(_ sender:UITapGestureRecognizer){
        
        let startFloat = Float64(startTime)
        let endFloat = Float64(endTime)
        let duration = endFloat - startFloat
        
        let startCMTime = CMTimeMakeWithSeconds(startFloat, player.currentTime().timescale)
        let endCMTime = CMTimeMakeWithSeconds(endFloat, player.currentTime().timescale)
        let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)

        //현재 진행중인 플레이어 stop
        player.pause()
        playerLayer.removeFromSuperlayer()
        audioPlayer.pause()
        audioPlayer.currentTime = TimeInterval(0)
        
        containedVideoCount += 1
        
        videosInfo.order.append(self.index)
        videosInfo.range.append(timeRange)
        
        print(videosInfo.order)
        print(videosInfo.range)
        
        addHomeAndDoneButton()
        trimmerView.removeFromSuperview()
        print("inserted!")
        
        
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
        
        //남은 초 표시
        stackedTime += self.endTime - self.startTime
        durationList.append(self.endTime - self.startTime)
        if stackedTime >= 15 {
            timeControlView.text = "0"
            warningLabel.isHidden = false
        }else{
            timeControlView.text = "\(15-stackedTime)"
            trimmerView.stackedTime = stackedTime
        }
        
    }
    
    //캔슬 버튼 눌렀을 때
    func touchCancelBtnAction(_ sender:UITapGestureRecognizer){
        player.pause()
        playerLayer.removeFromSuperlayer()
        audioPlayer.pause()
        audioPlayer.currentTime = TimeInterval(0)
        
        addHomeAndDoneButton()
        trimmerView.removeFromSuperview()
        print("cancel")
    }
    
    //삭제 기능
    func deleteVideoAction(_ sender:UITapGestureRecognizer){
        
        //프로그레스바 initialize
        progressBar.removeFromSuperview()
        width = 0
        temp = temp - bar
        
        //오디오 initialize
        audioPlayer.currentTime = TimeInterval(0)
        audioPlayer.pause()
        
        //video initialize
        if videosInfo.order.count > 0 {
            let tempItem = AVPlayerItem(url: videosInfo.videoURL[videosInfo.order[0]] as URL)
            resultPlayer.replaceCurrentItem(with: tempItem)
            resultPlayer.seek(to: videosInfo.range[0].start)
            resultPlayer.pause()
        }else{
            //resultPlayer를 널로 처리해야함
            //playerLayer.removeFromSuperlayer()
        }
        isResultVideoEnded = false
        count = 0
        
        //time reset
        stackedTime = stackedTime - durationList.popLast()!
        
        //삭제
        if videosInfo.order.count > 0 {
            
            containedVideoCount -= 1
            
            print(videosInfo.order)
            print(videosInfo.range)
            print(allocatedViews)
            
            videosInfo.order.removeLast()
            videosInfo.range.removeLast()
            
            allocatedViews.popLast()?.removeFromSuperview()
            
            if videosInfo.order.count > 0 {
                deleteButton.frame = CGRect(x: allocatedViews.last!.frame.width-20, y: 5, width: 15, height: 15)
                allocatedViews.last!.addSubview(deleteButton)
            }

            
            print(videosInfo.order)
            print(videosInfo.range)
            print(allocatedViews)
            
            warningLabel.isHidden = true
        }
        
        
        if videosInfo.order.count == 0 {
            playerLayer.removeFromSuperlayer()
            temp = 0
        }
        
        print("contained video : \(containedVideoCount)")
        if let token = timeObservationToken {
            resultPlayer.removeTimeObserver(token)
            timeObservationToken = nil
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
        audioPlayer.currentTime = TimeInterval(stackedTime)
    }
    
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        
        let numberOfPlaces = 1.0
        let multiplier:CGFloat = pow(10.0, CGFloat(numberOfPlaces))
        
        self.startTime = round(startTime * multiplier)/multiplier
        self.endTime = round(endTime * multiplier)/multiplier
        
        print("\(self.startTime) :  \(self.endTime)")
        print(Float64(self.startTime))
        
        player.seek(to: CMTimeMakeWithSeconds(Float64(self.startTime), 600))
        player.pause()
        audioPlayer.pause()
      
        //트리머에서 손 때면 음악들리게하라
        if trimmerView.isGestureEnd {
            self.player.play()
            self.audioPlayer.currentTime = TimeInterval(self.stackedTime)
            self.audioPlayer.play()
            self.startPlaybackTimeChecker()
        }
    }
    
    func trimmerView(_ trimmerView: ICGVideoTrimmerView!, isGestureEnd end: Bool) {
        if end == true {
            self.player.play()
            self.audioPlayer.currentTime = TimeInterval(self.stackedTime)
            self.audioPlayer.play()
            self.startPlaybackTimeChecker()
        }
    }
    
    func playerDidFinishPlaying(note: Notification){
        self.player.seek(to: kCMTimeZero)
        self.player.pause()
        self.audioPlayer.currentTime = TimeInterval(self.stackedTime)
        self.audioPlayer.pause()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
