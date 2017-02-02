//
//  MainPageViewController.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 11. 30..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit

final class MainPageViewController: UIPageViewController {
    
    // Indicates whether there is an image being captured in CameraViewController.
    
    var scrollView: UIScrollView?
    var recognize: UIGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global().async {
            for view in self.view.subviews {
                if (view is UIScrollView) {
                    self.scrollView = (view as! UIScrollView)
                    return
                }
            }
        }
        
        // UIPageViewControllerDataSource Delegate
        dataSource = self
        delegate = self
        
        // Show CameraViewController as first screen.
        if let cameraViewController = orderedViewControllers.last {
            setViewControllers([cameraViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
        
        // preload MusicViewContoller
        orderedViewControllers.first?.view.layoutSubviews()
        addObserver()
    }
    
    // Inject
    public var orderedViewControllers: [UIViewController]!
    
    // Create pageViewController item.
    private func newPageViewController(storyboardIdentifierPrefix idPrefix:String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(idPrefix)ViewController")
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func addObserver() {
        // Invoked when music is selected in MusicViewController -> Call from MusicViewController
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiverScrollToNext), name: Notification.Name(rawValue: "goToCameraPage"), object: nil)
        
        // Called when there is no video currently being recorded in CameraViewController and you want to go to MusicViewController. -> Call from CameraViewController
        NotificationCenter.default.addObserver(self, selector: #selector(self.recevierScrollToPrev), name: Notification.Name(rawValue: "goToMusicPage"), object: nil)
        
        // It tells you whether or not there is video currently being recorded. -> Call from CameraViewController
        NotificationCenter.default.addObserver(self, selector: #selector(self.recevierPresenceOfCurrentlyRecording), name: Notification.Name(rawValue: "recordStatusChange"), object: nil)
    }
    
    func receiverScrollToNext() {
        self.setViewControllers([orderedViewControllers.last!], direction: .forward, animated: true, completion: nil)
    }
    
    func recevierScrollToPrev() {
        self.setViewControllers([orderedViewControllers.first!], direction: .reverse, animated: true, completion: nil)
    }
    
    // Called for scrolling state change in CameraViewController
    func recevierPresenceOfCurrentlyRecording(nof: NSNotification) {
        
        let status = (nof.userInfo?["isBeingShot"] as! Bool)
    
        scrollView?.isScrollEnabled = status
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MainPageViewController: UIPageViewControllerDataSource {
    //Returns the previous viewcontroller.
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        return orderedViewControllers[previousIndex]
    }
    
    // Returns the next viewcontroller.
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        guard orderedViewControllers.count != nextIndex else {
            return nil
        }
        return orderedViewControllers[nextIndex]
    }
}

extension MainPageViewController: UIPageViewControllerDelegate {
    // Called before a gesture-driven transition begins.
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        // Close the search bar by calling the Music ViewController closeSearchBarWindow.
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "swipToCameraPage"), object: nil)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        // When paging occurs, it will clean up the temporary files and stacks of CameraViewController.
        // Call the cleanVideoandMusicStack function in CameraViewController
        
    }
}
