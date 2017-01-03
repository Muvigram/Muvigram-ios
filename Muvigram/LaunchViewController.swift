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
            alert.title = title
            alert.message = nil
            alert.cancel = "Cancel"
            alert.settings = "Settings"
        }
        
        func requestAccess(permission: Permission, title: String, _ complete: @escaping () -> Void) {
                showAlert(permission, title)
                permission.request{ status in
                    switch status {
                    case .authorized:
                        complete()
                        break
                    default:
                        requestAccess(permission: permission, title: title, complete)
                        }
                    }
            }
        
        requestAccess(permission: .camera, title: "Please allow access to your camera") {
            requestAccess(permission: .mediaLibrary, title: "Please allow access to your mediaLibrary") {
                requestAccess(permission: .microphone, title: "Please allow access to your microphone") {
                    requestAccess(permission: .photos, title: "Please allow access to your photos") {
                        DispatchQueue.main.async { self.present(self.mainViewController, animated: true, completion: nil) }
                    }
                }
            }
        }
    }
}
