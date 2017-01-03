//
//  AppDelegate.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 11. 30..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import Swinject
import SwinjectStoryboard

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    var window: UIWindow?
    let container: Container = Container() { container in
        container.register(MusicService.self) { _ in MusicService()}
        container.register(VideoService.self) {_ in VideoService()}
        
        container.register(DataManager.self) { r in
            DataManager(musicService: r.resolve(MusicService.self)!, videoService: r.resolve(VideoService.self)!)
            }.inObjectScope(.container)
        
        container.register(MusicPresenter.self) {r in
            MusicPresenter<MusicViewController>(dataManager: r.resolve(DataManager.self)!)
        }
        
        container.register(CameraPresenter.self) { r in
            CameraPresenter<CameraViewController>(dataManager: r.resolve(DataManager.self)!)
        }
        
        // Views
        container.registerForStoryboard(MusicViewController.self) { r, c in
            let presenter = r.resolve(MusicPresenter<MusicViewController>.self)!
            presenter.attachView(view: c)
            c.presenter = presenter
        }
        container.registerForStoryboard(CameraViewController.self) { r, c in
            let presenter = r.resolve(CameraPresenter<CameraViewController>.self)!
            presenter.attachView(view: c)
            c.presenter = presenter
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor.white
        window.makeKeyAndVisible()
        self.window = window
        let bundle = Bundle(for: LaunchViewController.self)
        let storyBoard = SwinjectStoryboard.create(name: "Main", bundle: bundle, container: container)
        
        container.registerForStoryboard(MainPageViewController.self) { r, c in
            c.orderedViewControllers = [storyBoard.instantiateViewController(withIdentifier: "MusicViewController"),
                                        storyBoard.instantiateViewController(withIdentifier: "CameraViewController")]
        }
        
        container.registerForStoryboard(LaunchViewController.self) { r, c in
            c.mainViewController = storyBoard.instantiateViewController(withIdentifier: "MainPage") as! MainPageViewController
        }
        
        window.rootViewController = storyBoard.instantiateInitialViewController()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

