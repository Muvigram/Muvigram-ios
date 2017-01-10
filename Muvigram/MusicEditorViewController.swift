//
//  MusicEditorViewController.swift
//  Muvigram
//
//  Created by 박정이 on 2017. 1. 10..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import UIKit

class MusicEditorViewController: UIViewController {

    var videosInfo = VideosInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("유알엘 리스트에요.")
        print(videosInfo.videoURL)
        print(videosInfo.isVertical)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "editorSegue"){
            let vc = segue.destination as! EditorViewController
            vc.videosInfo = videosInfo
        }
        
    }

}
