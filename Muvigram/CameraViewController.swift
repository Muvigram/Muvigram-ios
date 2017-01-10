//
//  CameraViewController.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 11. 30..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import Permission
import MediaPlayer
import RxSwift
import RxCocoa
import Swinject
import SwinjectStoryboard
import SCWaveformView
import CTAssetsPickerController

final class CameraViewController: UIViewController, CTAssetsPickerControllerDelegate {

    @IBOutlet var musicSelectBtn: AlbumButton!
    @IBOutlet var cameraTopline: UIView!
    @IBOutlet var stackBar: StackBar!
    @IBOutlet var previewView: PreviewView!
    @IBOutlet var switchCameraBtn: UIButton!
    @IBOutlet var audioEditBtn: UIButton!
    @IBOutlet var recordBtn: UIButton!
    @IBOutlet var videoEditComplateBtn: UIButton!
    @IBOutlet var libraryBtn: UIButton!
    @IBOutlet var cameraToplineView: UIView!
    @IBOutlet var scwaveScrollView: SCScrollableWaveformView!
    @IBOutlet var testBtn: UIButton!
    let stackViewPopBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 34, height: 40))
    
    // @inject
    public var presenter: CameraPresenter<CameraViewController>!
    public var shardViewController: ShareViewController!
    
    // Session
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var setupResult: SessionSetupResult = .success
    private let session = AVCaptureSession()
    fileprivate var sessionQueue = DispatchQueue(label: "session queue")
    private var isSessionRunning = false
    
    // Input and Output
    fileprivate var videoDiviceInput: AVCaptureDeviceInput!
    fileprivate var movieFileOutput: AVCaptureFileOutput?
    fileprivate var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    // VideoPicker  - jeongyi
    let imagePicker = CTAssetsPickerController()
    let assetsGridSelectedView = CTAssetsGridViewCell()
    let assetsSelectionLabel = CTAssetSelectionLabel()
    let videoInfo = VideosInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Music Unselected music files are replaced with no sound. // OK
        presenter.viewDidLoad()
        presenter.loadVideos()
        
        addObserver()
        
        viewInitialization()
        
        // Session connection to preview
        previewView.session = session
        
        sessionQueue.async { [unowned self] in
            self.congfigureSession()
        }
        
        // Stop recording
        let recordButtonRecordingStopEvent = recordBtn.rx.controlEvent(
            [UIControlEvents.touchUpInside, UIControlEvents.touchDragOutside,UIControlEvents.touchCancel, UIControlEvents.touchUpOutside])
        
        presenter.recordButtonStopRecordEvent(event: recordButtonRecordingStopEvent)
        
        // Start recording
        let recordButtonRecordingStartEvent = recordBtn.rx.controlEvent(UIControlEvents.touchDown)
        presenter.recordButtonStartRecordEvent(event: recordButtonRecordingStartEvent)
        
        // Go to MusicViewController
        let musicSelectButtonEvent = musicSelectBtn.rx.controlEvent(UIControlEvents.touchUpInside)
        presenter.musicSelectButtonEvent(event: musicSelectButtonEvent)

        // Click the Audio Edit button to show the waveform and hide other views.
        let audioEditButtonEvent = audioEditBtn.rx.controlEvent(UIControlEvents.touchUpInside)
        presenter.audioEditButtonEvent(event: audioEditButtonEvent)
        
        // Go to ShareViewController when video recording is complete
        let videoEditComplateButtonEvent = videoEditComplateBtn.rx.controlEvent(UIControlEvents.touchUpInside)
        presenter.videoEditComplateButtonEvent(event: videoEditComplateButtonEvent)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        shardViewController = nil
        
        // Initialize the state each time the CameraViewController appears on the screen again.
        self.stackBar.clearStack()
        self.cleanVideoandMusicStack()
        presenter.viewWillAppear()
        viewInitialization()
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case .notAuthorized: fallthrough
            default: break
            }
        }
    }
    
    func viewInitialization() {
        audioEditBtn.isEnabled = false
        videoEditComplateBtn.isEnabled = false
        
        // Stack Button ans stackBar Settings
        stackBar.delegate = self
        stackViewPopBtn.addTarget(stackBar, action: #selector(stackBar.popStack), for: UIControlEvents.touchUpInside)
        stackViewPopBtn.setImage(UIImage(named: "stackPop"), for: .normal)
        stackViewPopBtn.isHidden = true
        view.addSubview(stackViewPopBtn)
        
        // SCWaveScrollView Settings
        testBtn.isHidden = true
        scwaveScrollView.isHidden = true
        scwaveScrollView.showsVerticalScrollIndicator = false
        scwaveScrollView.showsHorizontalScrollIndicator = false
        scwaveScrollView.bounces = false
        scwaveScrollView.delegate = self
        scwaveScrollView.cmDelegate = self
    }
    
    private func congfigureSession() {
        guard setupResult == .success else {
            print("authorizationStatus is notDetermined")
            return
        }
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        // Camera settings
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Select Dual Camera, otherwise select Wide Angle Camera as default
            if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .back) {
                defaultVideoDevice = dualCameraDevice
            }
            else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
                defaultVideoDevice = backCameraDevice
            }
            else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            //Connect to an input device session
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDiviceInput = videoDeviceInput
            }
        } catch {
            print("Could not add video device input to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        congfigure3Amode()
        
        // Audio device settings
        do {
            let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                setupResult = .configurationFailed
                print("Could not add audio device input to the session")
            }
            
        } catch {
            setupResult = .configurationFailed
            print("Could not create audio device input: \(error)")
        }
        
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        let movieFileOutputConnection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo)
        movieFileOutputConnection?.videoOrientation = previewView.videoPreviewLayer.connection.videoOrientation
        //Connect to an output device session
        if session.canAddOutput(movieFileOutput) {
            session.addOutput(movieFileOutput)
            
            // Enable video stabilization to create additional latency in the video capture pipeline
            // to accommodate capture format and frame rate, and allow more system memory to be used.
            if let connection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.movieFileOutput = movieFileOutput
        } else {
            setupResult = .configurationFailed
            print("Could not add movie file output to the session")
        }
        session.commitConfiguration()
    }
    
    // 3A Mode settings
    private func congfigure3Amode(){
        if let device = self.videoDiviceInput.device {
            do {
                try device.lockForConfiguration()
                
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                device.unlockForConfiguration()
            }
            catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }

    /* Called when there is a right swipe gesture.
       Calling this method means that there is no video being recorded.
       If there is any video being recorded, the Scroll of the ScrollView is disabled
       and the gesture of the CameraViewContoller is enabled. This method is not called
       if ScrollView is enabled. 
     */
    @IBAction func swipGestureRecongizer(_ sender: UISwipeGestureRecognizer) {
        self.moveToMusicViewController()
    }
    
    func cleanVideoandMusicStack() { // OK
        self.presenter.clearMusicAndVideo()
    }
    
    // Camera Change
    @IBAction func changeCamera(_ sender: UIButton) {
        sessionQueue.async { [unowned self] in
            let currentVideoDevice = self.videoDiviceInput.device
            let currentPosition = currentVideoDevice!.position
            
            let preferredPosition: AVCaptureDevicePosition
            let preferredDeviceType: AVCaptureDeviceType
        
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDuoCamera
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
            }
            let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDuoCamera], mediaType: AVMediaTypeVideo, position: .unspecified)!.devices!
            var newVideoDevice: AVCaptureDevice? = nil
            // First, look for a device with both the preferred position and device type. 
            // Otherwise, look for a device with only the preferred position.
            if let device = devices.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
                newVideoDevice = device
            }
            else if let device = devices.filter({ $0.position == preferredPosition }).first {
                newVideoDevice = device
            }
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Using both front and rear cameras at the same time is not supported,
                    // so remove the old device input first.
                    self.session.removeInput(self.videoDiviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
    
                        self.session.addInput(videoDeviceInput)
                        self.videoDiviceInput = videoDeviceInput
                    }
                    else {
                        self.session.addInput(self.videoDiviceInput);
                    }
                    
                    if let connection = self.movieFileOutput?.connection(withMediaType: AVMediaTypeVideo) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.session.commitConfiguration()
                }
                catch {
                    print("Error occured while creating video device input: \(error)")
                }
            }
        }
        congfigure3Amode()
    }
    
    //Invoked when music is selected in the Music ViewController
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiverMusicSelelted), name: NSNotification.Name("receiverMusicSelelted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.cleanVideoandMusicStack), name: NSNotification.Name("cleanVideoandMusicStack"), object: nil)
    }
    
    // Communicating with MusicTableViewController
    // Invoke the selected item in MusicViewController as an argument
    func receiverMusicSelelted(nof: NSNotification) { 
        let item = nof.userInfo?["MPMediaItem"] as! MPMediaItem
        presenter.selectMusicfromList(item: item)
    }
    
   
    
    @IBAction func testShow(_ sender: Any) {
        self.presenter.touchTestShow()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func accessLibraryAction(_ sender: Any) {
        imagePicker.delegate = self
        imagePicker.showsSelectionIndex = true
        imagePicker.defaultAssetCollection = .smartAlbumVideos
        present(imagePicker, animated: true, completion: nil)
    }
    
    
}

// Saving and merging video files.
// Delegate on AVCaptureFileOutputRecording
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    // This method is called when the file output has started writing data to a file.
    // If an error condition prevents any data from being written, this method may not be called.
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!,
                 fromConnections connections: [Any]!, error: Error!) {
        guard error == nil else {
            print("Movie file finishing error: \(error)")
            return
        }
        self.presenter.capture(didFinishRecordingToOutputFileAt: outputFileURL)
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        self.presenter.captureWithFileWrite()
    }
}

// Deceleration removed for accurate range measurement
// Music stops when scrolling
// Play music on scrolling stop
extension CameraViewController: UIScrollViewDelegate, CmTimeDelegate  {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(scrollView.contentOffset, animated: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { //OK
        self.presenter.modifyPlayerPause()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { //OK
        self.presenter.modifyPlayerPlay()
    }
    func currentlySelectedPlaybackRange(_ range: CMTimeRange, end: CMTime) { //OK
        self.presenter.setModifyPlayerRange(range, end: end)
    }
}

extension CameraViewController: StackBarCurrentDelegate {
    func onStackBarCoordChanged(stackCurredCoord: CGPoint, width: CGFloat) {
        presenter.stackChangeWithCoord(stackCurredCoord, width)
    }
    
    func onStackBarPop() {
        presenter.stackBarPop()
    }
    
    func minimumRecordingtimeComplete() {
        presenter.minimumRecordingtimeComplete()
    }
    
    func minimumRecordingtimeLess() {
        presenter.minimumRecordingtimeLess()
    }
}

extension CameraViewController: CameraMvpView {
    func videoEditComplateButtonEnableWithStackBarStatus(status: Bool) {
        guard videoEditComplateBtn.isEnabled != status else {
            return
        }
        self.videoEditComplateBtn.isEnabled = status
    }
    
    func popButtonPositionChangeWithStackBarStatus(buttonImage: UIImage, buttonPosition: CGRect) {
        stackViewPopBtn.setImage(buttonImage, for: .normal)
        stackViewPopBtn.frame = buttonPosition
    }
    
    func popButtonHidden(status: Bool) {
        stackViewPopBtn.isHidden = status
    }
    
    func switchCameraButtonEnabled(enabled: Bool) {
        switchCameraBtn.isEnabled = enabled
    }
    
    func audioEditButtonEnabled(enabled: Bool) {
        audioEditBtn.isEnabled = enabled
    }
    
    func recordButtonEnabled(enabled: Bool) {
        recordBtn.isEnabled = enabled
    }
    
    func musicAlbumImageReplace(albumImage: UIImage) {
        musicSelectBtn.albumImage = albumImage
    }
    
    func recordButtonSendActionTouchUpInside() {
        recordBtn.sendActions(for: .touchUpInside)
    }
    
    func stackingStartWithStackBar(time: Float64) {
        stackBar.startStacking(time: time)
    }
    
    func stackingStopWithStackBar() {
        self.stackBar.stopStacking()
    }
    
    func setWaveformViewAsset(asset: AVAsset) {
        scwaveScrollView.waveformView.asset = asset
    }
    
    func setWaveformViewPrecision() {
        scwaveScrollView.waveformView.precision = 1
    }
    
    func setWaveformViewTimeRange(range: CMTimeRange) {
        scwaveScrollView.waveformView.timeRange = range
    }
    
    func setWaveformViewProgress(time: CMTime) {
        scwaveScrollView.waveformView.progressTime = time
    }
    
    func getWaveformViewTimeRangeStart() -> CMTime {
        return scwaveScrollView.waveformView.timeRange.start
    }
    
    func getWaveformViewAssetDuration() -> CMTime {
        return scwaveScrollView.waveformView.asset.duration
    }
    
    func partialRecordingComplete() {
        //Stop recording, so the stack bar stops.
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }
        if movieFileOutput.isRecording {
            movieFileOutput.stopRecording()
        }
    }
    
    func partialRecordingStarted() {
        // Now that we have started recording, let the stack bar move.
        stackBar.push()
        popButtonHidden(status: true)
        // Stop scrolling to start recording
        scrollExclusiveOr(false)
        switchCameraButtonEnabled(enabled: false)
        audioEditButtonEnabled(enabled: false)
        
        sessionQueue.async { [unowned self] in
            if !self.movieFileOutput!.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    /*
                     Tells the OS that the job is running in the background
                     Otherwise, the capture callback, AVCaptureFileOutputRecordingDelegate imp,
                     will not be called until it returns to the foreground
                     Also, if you switch to the background, you can be guaranteed time to write or erase the file.
                     */
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                let outputFileName = UUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString)
                    .appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                self.movieFileOutput!.startRecording(toOutputFileURL: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            }
        }
    }
    
    // Disable scrolling if there is an video being recorded,
    // and activate scrolling if there is no video being recorded.
    // RecevierPresenceOfCurrentlyRecording () call in Main PageViewController
    func scrollExclusiveOr(_ enabled: Bool) {
        NotificationCenter.default.post( name: NSNotification.Name("recordStatusChange"), object: nil, userInfo: ["isBeingShot": enabled])
    }
    
    func videoRecordingFinalized(videoUrlArray: [URL], musicTimeStampArray: [CMTime], musicUrl: URL) {
      
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        shardViewController = appDelegate.newShareViewControllerInstance()
        shardViewController.videoUrlArray = videoUrlArray
        shardViewController.musicTimeStampArray = musicTimeStampArray
        shardViewController.musicUrl = musicUrl
        self.present(self.shardViewController, animated: true, completion: nil)
    }
    
     // Hides the view according to the recording or interval selection.
    func controllerViewisHidden(_ hidden: Bool, isRecord: Bool) {
        func commonViewHidden(_ show: Bool) {
            self.musicSelectBtn.isHidden = show
            self.audioEditBtn.isHidden = show
            self.switchCameraBtn.isHidden = show
            self.videoEditComplateBtn.isHidden = show
            self.libraryBtn.isHidden = show
            self.cameraTopline.isHidden = show
        }
        // Recording
        if hidden, isRecord {
            commonViewHidden(true)
        } else if hidden, !isRecord {
            // Selecting segment
            commonViewHidden(true)
            self.recordBtn.isHidden = true
            self.stackBar.isHidden = true
            self.scwaveScrollView.isHidden = false
            self.testBtn.isHidden = false
        } else if !hidden, !isRecord {
            // Complete section selection
            commonViewHidden(false)
            self.recordBtn.isHidden = false
            self.stackBar.isHidden = false
            self.scwaveScrollView.isHidden = true
            self.testBtn.isHidden = true
        } else {
            // Complete Record
            commonViewHidden(false)
        }
    }
    
    // Moving to MusicViewContoller during video  recording deletes all video being shot.
    // Confirm in the UIAlertController whether or not to actually move.
    func moveToMusicViewController() {
        guard scwaveScrollView.isHidden else {
            return
        }
        //Actual move request from MainPageViewController
        func goToMusicController() {
            NotificationCenter.default.post(name: NSNotification.Name("goToMusicPage"), object: nil)
        }
        if presenter.isVidioFileUrlEmpty() {
            // Move if there is no video being recorded
            goToMusicController()
        } else {
            // Ask user if there is video being recorded
            let alart = UIAlertController(
                title: "Currently recording",
                message: "If you move the screen while recording video, the video being recorded is deleted.\n Are you sure you want to move?",
                preferredStyle: .alert)
            alart.addAction(UIAlertAction(title: "Calcel", style: .cancel, handler: nil))
            
            // Removes all Video being recorded because the user wants to go to the MusicViewContoller.
            alart.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
                goToMusicController()
            }))
            self.present(alart, animated: true, completion: nil)
        }
    }
    
    func setlibraryButtonImage(_ image: UIImage) {
        libraryBtn.setImage(image, for: .normal)
    }
    
    
}
