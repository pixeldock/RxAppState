//
//  UILabel+Rx.swift
//  RxAppState
//
//  Created by Jörn Schoppe on 06.03.16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAppState

extension UILabel {
    public var rx_appState: AnyObserver<AppState> {
        return Binder(self) { label, appState in
            switch appState {
            case .active:
                label.backgroundColor = UIColor.green
                label.text = "ACTIVE"
            case .inactive:
                label.backgroundColor = UIColor.yellow
                label.text = "INACTIVE"
            case .background:
                label.backgroundColor = UIColor.red
                label.text = "BACKGROUND"
            case .terminated:
                label.backgroundColor = UIColor.lightGray
                label.text = "TERMINATED"
            }
        }
        .asObserver()
    }
    
    public var rx_firstLaunch: AnyObserver<Bool> {
        return Binder(self) { label, isFirstLaunch in
            if isFirstLaunch {
                label.backgroundColor = UIColor.green
                label.text = "YES"
            } else {
                label.backgroundColor = UIColor.red
                label.text = "NO"
            }
        }
        .asObserver()
    }
    
    public var rx_viewState: AnyObserver<ViewControllerViewState> {
        return Binder(self) { label, appState in
            switch appState {
            case .viewDidLoad:
                label.text = "VIEW DID LOAD"
            case .viewDidLayoutSubviews:
                label.text = "VIEW DID LAYOUT SUBVIEWS"
            case .viewWillAppear:
                label.text = "VIEW WILL APPEAR"
            case .viewIsAppearing:
                label.text = "VIEW IS APPEARING"
            case .viewDidAppear:
                label.text = "VIEW DID APPEAR"
            case .viewWillDisappear:
                label.text = "VIEW WILL DISAPPEAR"
            case .viewDidDisappear:
                label.text = "VIEW DID DISAPPEAR"
            }
            }
            .asObserver()
    }
}
