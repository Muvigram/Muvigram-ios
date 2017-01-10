//
//  BasePresenter.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 23..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import Foundation

class BasePresenter<T: Mvpview> {
    public weak var view: T?

    init() {
    }
    // inject
    public func attachView(view: T) {
        self.view = view
    }
}
