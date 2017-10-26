//
//  UIApplication+Rx.swift
//  Pods
//
//  Created by Jörn Schoppe on 29.02.16.
//  Copyright © 2015 Jörn Schoppe. All rights reserved.
//

import RxSwift
import RxCocoa

/**
 UIApplication states
 
 There are two more app states in the Apple Docs ("Not running" and "Suspended").
 I decided to ignore those two states because there are no UIApplicationDelegate
 methods for those states.
 */
public enum AppState: Equatable {
    /**
     The application is running in the foreground.
     */
    case active
    /**
     The application is running in the foreground but not receiving events.
     Possible reasons:
     - The user has opens Notification Center or Control Center
     - The user receives a phone call
     - A system prompt is shown (e.g. Request to allow Push Notifications)
     */
    case inactive
    /**
     The application is in the background because the user closed it.
     */
    case background
    /**
     The application is about to be terminated by the system
     */
    case terminated
}

/**
 Equality function for AppState
 */
public func ==(lhs: AppState, rhs: AppState) -> Bool {
    switch (lhs, rhs) {
    case (.active, .active),
    (.inactive, .inactive),
    (.background, .background),
    (.terminated, .terminated):
        return true
    default:
        return false
    }
}

public struct RxAppState {
    /**
     Allows for the app version to be stored by default in the main bundle from `CFBundleShortVersionString` or
     a custom implementation per app.
     */
    public static var currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
}

extension RxSwift.Reactive where Base: UIApplication {
    
    /**
     Keys for NSUserDefaults
     */
    fileprivate var isFirstLaunchKey:   String { return "RxAppState_isFirstLaunch" }
    fileprivate var numDidOpenAppKey:   String { return "RxAppState_numDidOpenApp" }
    fileprivate var lastAppVersionKey:  String { return "RxAppState_lastAppVersion" }

    /**
     App versions
     */
    fileprivate var appVersions: (last: String, current: String) {
        return (last: UserDefaults.standard.string(forKey: self.lastAppVersionKey) ?? "",
                current: RxAppState.currentAppVersion ?? "")
    }
    
    /**
     Reactive wrapper for `delegate`.
     
     For more information take a look at `DelegateProxyType` protocol documentation.
     */
    var delegate: RxApplicationDelegateProxy {
        return RxApplicationDelegateProxy.proxy(for: base)
    }
    
    /**
     Reactive wrapper for `delegate` message `applicationDidBecomeActive(_:)`.
     */
    public var applicationDidBecomeActive: Observable<AppState> {
        return delegate.methodInvoked(#selector(UIApplicationDelegate.applicationDidBecomeActive(_:)))
            .map { _ in
                return .active
        }
    }
    
    /**
     Reactive wrapper for `delegate` message `applicationDidEnterBackground(_:)`.
     */
    public var applicationDidEnterBackground: Observable<AppState> {
        return delegate.methodInvoked(#selector(UIApplicationDelegate.applicationDidEnterBackground(_:)))
            .map { _ in
                return .background
        }
    }
    
    /**
     Reactive wrapper for `delegate` message `applicationWillResignActive(_:)`.
     */
    public var applicationWillResignActive: Observable<AppState> {
        return delegate.methodInvoked(#selector(UIApplicationDelegate.applicationWillResignActive(_:)))
            .map { _ in
                return .inactive
        }
    }
    
    /**
     Reactive wrapper for `delegate` message `applicationWillTerminate(_:)`.
     */
    public var applicationWillTerminate: Observable<AppState> {
        return delegate.methodInvoked(#selector(UIApplicationDelegate.applicationWillTerminate(_:)))
            .map { _ in
                return .terminated
        }
    }
    
    /**
     Observable sequence of the application's state
     
     This gives you an observable sequence of all possible application states.
     
     - returns: Observable sequence of AppStates
     */
    public var appState: Observable<AppState> {
        return Observable.of(
            applicationDidBecomeActive,
            applicationWillResignActive,
            applicationDidEnterBackground,
            applicationWillTerminate
            )
            .merge()
    }
    
    /**
     Observable sequence that emits a value whenever the user opens the app
     
     This is a handy sequence if you want to run some code everytime
     the user opens the app.
     It ignores `applicationDidBecomeActive(_:)` calls when the app was not
     in the background but only in inactive state (because the user
     opened control center or received a call).
     
     Typical use cases:
     - Track when the user opens the app.
     - Refresh data on app start
     
     - returns: Observable sequence of Void
     */
    public var didOpenApp: Observable<Void> {
        return Observable.of(
            applicationDidBecomeActive,
            applicationDidEnterBackground
            )
            .merge()
            .distinctUntilChanged()
            .filter { $0 == .active }
            .map { _ in
                return
        }
    }
    
    /**
     Observable sequence that emits the number of times a user has opened the app
     
     This is a handy sequence if you want to know how many times the user has opened your app
     
     Typical use cases:
     - Ask a user to review your app after when he opens it for the 10th time
     - Track the number of times a user has opened the app
     
     -returns: Observable sequence of Int
     */
    public var didOpenAppCount: Observable<Int> {
        return didOpenApp
            .map { _ in
                let userDefaults = UserDefaults.standard
                var count = userDefaults.integer(forKey: self.numDidOpenAppKey)
                count = min(count + 1, Int.max - 1)
                userDefaults.set(count, forKey: self.numDidOpenAppKey)
                userDefaults.synchronize()
                return count
        }
    }
    
    /**
     Observable sequence that emits if the app is opened for the first time when the user opens the app
     
     This is a handy sequence for all the times you want to run some code only
     when the app is launched for the first time
     
     Typical use case:
     - Show a tutorial to a new user
     
     -returns: Observable sequence of Bool
     */
    public var isFirstLaunch: Observable<Bool> {
        return didOpenApp
            .map { _ in
                let userDefaults = UserDefaults.standard
                let didLaunchBefore = userDefaults.bool(forKey: self.isFirstLaunchKey)
                
                if didLaunchBefore {
                    return false
                } else {
                    userDefaults.set(true, forKey: self.isFirstLaunchKey)
                    userDefaults.synchronize()
                    return true
                }
        }
    }
    
    /**
     Observable sequence that emits if the app is opened for the first time after an app has updated when the user
     opens the app. This does not occur on first launch of a new app install. See `isFirstLaunch` for that.
     
     This is a handy sequence for all the times you want to run some code only when the app is launched for the
     first time after an update.
     
     Typical use case:
     - Show a what's new dialog to users, or prompt review or signup
     
     -returns: Observable sequence of Bool
     */
    public var isFirstLaunchOfNewVersion: Observable<Bool> {
        return didOpenApp
            .map { _ in
                let (lastAppVersion, currentAppVersion) = self.appVersions
                
                if lastAppVersion.isEmpty || lastAppVersion != currentAppVersion {
                    UserDefaults.standard.set(currentAppVersion, forKey: self.lastAppVersionKey)
                    UserDefaults.standard.synchronize()
                }
                
                if !lastAppVersion.isEmpty && lastAppVersion != currentAppVersion {
                    return true
                } else {
                    return false
                }
        }
    }
    
    /**
     Observable sequence that just emits one value if the app is opened for the first time for a new version
     or completes empty if this version of the app has been opened before
     
     This is a handy sequence for all the times you want to run some code only when a new version of the app
     is launched for the first time
     
     Typical use case:
     - Show a what's new dialog to users, or prompt review or signup
     
     -returns: Observable sequence of Void
     */
    public var firstLaunchOfNewVersionOnly: Observable<Void> {
        return Observable.create { observer in
            let (lastAppVersion, currentAppVersion) = self.appVersions
            let isUpgraded = (!lastAppVersion.isEmpty && lastAppVersion != currentAppVersion)

            if isUpgraded {
                UserDefaults.standard.set(currentAppVersion, forKey: self.lastAppVersionKey)
                UserDefaults.standard.synchronize()
                observer.onNext()
            }
            observer.onCompleted()
            return Disposables.create {}
        }
    }

    /**
     Observable sequence that just emits one value if the app is opened for the first time
     or completes empty if the app has been opened before
     
     This is a handy sequence for all the times you want to run some code only
     when the app is launched for the first time
     
     Typical use case:
     - Show a tutorial to a new user
     
     -returns: Observable sequence of Void
     */
    public var firstLaunchOnly: Observable<Void> {
        return Observable.create { observer in
            let userDefaults = UserDefaults.standard
            let didLaunchBefore = userDefaults.bool(forKey: self.isFirstLaunchKey)
            
            if !didLaunchBefore {
                userDefaults.set(true, forKey: self.isFirstLaunchKey)
                userDefaults.synchronize()
                observer.onNext()
            }
            observer.onCompleted()
            return Disposables.create {}
        }
    }
    
}
