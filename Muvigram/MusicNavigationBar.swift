//
//  MusicNavigationBar.swift
//  Muvigram
//
//  Created by GangGongUi on 2017. 1. 13..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import UIKit

class MusicNavigationBar: UISearchController {
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.barTintColor = UIColor(red: CGFloat(0.984), green: CGFloat(0.984), blue: CGFloat(0.984), alpha: CGFloat(1.00))
        self.view.addSubview(searchBar)
    }
}
