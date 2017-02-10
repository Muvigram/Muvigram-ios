//
//  LaunchViewController.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 27..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import Permission
import MediaPlayer


class LaunchViewController: UIViewController {

    // @Inject
    var mainViewController: MainPageViewController!
    
    override func viewDidLoad() {
        MPMediaLibrary.requestAuthorization { _ in }
        requestPermissionAccess()
    }
    
    private func requestPermissionAccess() {
        func showAlert(_ permission: Permission, _ title: String) {
            let alert = permission.prePermissionAlert
            alert.title = "Please allow access to your \(title)"
            alert.message = nil
            alert.cancel = "Cancel"
            alert.settings = "Settings"
        }
        
        func requestAccess(_ permission: Permission, title: String, _ complete: @escaping () -> Void) {
                showAlert(permission, title)
                permission.request{ status in
                    switch status {
                    case .authorized:
                        complete()
                        break
                    default:
                        requestAccess(permission, title: title, complete)
                    }
                }
            }
        
        requestAccess(.camera, title: "camera") {
            requestAccess(.mediaLibrary, title: "mediaLibrary") {
                requestAccess(.microphone, title: "microphone") {
                    requestAccess(.photos, title: "photos") {
                        let delay = DispatchTime.now() + 1
                        DispatchQueue.main.asyncAfter(deadline: delay) {
                            self.present(self.mainViewController, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
}
