# RxAppState

[![CI Status](https://img.shields.io/travis/com/pixeldock/RxAppState.svg?style=flat)](https://travis-ci.com/pixeldock/RxAppState)
[![Platform](https://img.shields.io/cocoapods/p/RxAppState.svg?style=flat)](http://cocoapods.org/pods/RxAppState)
[![Version](https://img.shields.io/cocoapods/v/RxAppState.svg?style=flat)](http://cocoapods.org/pods/RxAppState)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-E05C43.svg?style=flat)](https://swift.org/package-manager/)
[![Xcode](https://img.shields.io/badge/xcode-12-5995EE.svg?style=flat)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org/)
[![License](https://img.shields.io/cocoapods/l/RxAppState.svg?style=flat)](http://cocoapods.org/pods/RxAppState)
[![Twitter](https://img.shields.io/badge/Twitter-@pixeldock-5E9FE5.svg?logo=twitter)](http://twitter.com/pixeldock)
[![Blog](https://img.shields.io/badge/Blog-pixeldock-FF0066.svg?style=flat)](http://pixeldock.com/blog)

A collection of handy RxSwift Observables that let you observe all the changes in your Application's state and your UIViewController view-related notifications.

## About
### Application states
In almost every app there is some code that you want to run each time a user opens the app. For example you want to refresh some data or track that the user opened your app.

**UIApplicationDelegate** offers two methods that you could use to run the code when the user opens the app: _applicationWillEnterForeground_ and _applicationDidBecomeActive_. But either of these methods is not ideal for this case:

_applicationWillEnterForeground_ is not called the first time your app is launched. It is only called when the app was in the background and then enters the foreground. At first launch the app is not in the background state so this methods does not get called.

_applicationDidBecomeActive_ does get called when the app is launched for the first time but is also called when the app becomes active after being in inactive state. That happens everytime the user opens Control Center, Notification Center, receives a phone call or a system prompt is shown (e.g. to ask the user for permission to send remote notifications). So if you put your code in _applicationDidBecomeActive_ it will not only get called when the user opens the app but also in all those cases mentioned above.

So to really run your code only when your user opens the app you need to keep track of the app's state. You would probably implement something like this:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var didEnterBackground = true
    ...
    func applicationDidEnterBackground(_ application: UIApplication) {
        didEnterBackground = true
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        if didEnterBackground {
            // run your code
            didEnterBackground = false
        }
    }
    ...
}
```
This is not a big problem, but it is not a very elegant approach. And you have to set the inital value of _didEnterBackground_ to _true_ to run your code after the first launch (see above), even if the app never has been to the background. Call me picky, but I don't like that.

**RxAppState to the rescue!**  
With RxAppState you can simply do the following:

```swift
UIApplication.shared.rx.didOpenApp
    .subscribe(onNext: { _ in
        // run your code
    })
    .disposed(by: disposeBag)
```
This runs your code whenever the user opens the app. It includes the first launch of the app and ignores the cases when the app enters active state without having been in background state before (like when the user just opened Control Center or received a phone call)

**And there is more!**  
You want to show your user a tutorial when he first launches the app? And you only want to show it after the first launch and never again? No problem:

```swift
UIApplication.shared.rx.firstLaunchOnly
    .subscribe(onNext: { _ in
        // run your code
    })
    .disposed(by: disposeBag)
```
You want to show your user what features are new when he opens the app for the first time after an update?

```swift
UIApplication.shared.rx.firstLaunchOfNewVersionOnly
    .subscribe(onNext: { version in
        let previousAppVersion = version.previous
        let currentAppVersion = version.current
        // show what has changed between
        // the previous and the current version
    })
    .disposed(by: disposeBag)
```

You want check the previous and the current app version each time the user opens the app?

```swift
UIApplication.shared.rx.appVersion
    .subscribe(onNext: { version in
        let previousAppVersion = version.previous
        let currentAppVersion = version.current
        // run your code
    })
    .disposed(by: disposeBag)
```

You want to keep track of how many times the user has opened your app? Simply do this:

```swift
UIApplication.shared.rx.didOpenAppCount
    .subscribe(onNext: { count in
        print("app opened \(count) times")
    })
    .disposed(by: disposeBag)
```

**The cherry on top:**   
This code does not have to live in your AppDelegate. You could put it anywhere you like in your app! So don't clutter your AppDelegate with this code, put it somewhere else!

### ViewController view-related notifications

You can also use Observables to subscribe to your view controllers' view-related notifications:

Do do something when your view controller's `viewDidAppear:` method is called you can do this in your view controller class:

```swift
rx.viewDidAppear
    .subscribe(onNext: { animated in
       // do something
    })
    .disposed(by: disposeBag)
```

If you want to do something only when the view appeared for the first time you can easily do it like this:

```swift
rx.viewDidAppear
    .take(1)
    .subscribe(onNext: { animated in
       // do something
    })
    .disposed(by: disposeBag)
```

You can also directly bind you view controller's view state to another object:

```swift
rx.viewWillDisappear
    .bind(to: viewModel.saveChanges)
    .disposed(by: disposeBag)
```


## Example
There is a simple example project to demonstrate how to use RxAppDelegate.

## Requirements
iOS 13   
Swift 5.2
Xcode 15 
If you are still on Xcode 14 you can try to use the branch `/fix/xcode14-viewIsAppearing' (at own risk)


If you are using Swift 4.0 please use RxAppState version 1.1.1  
If you are using Swift 4.1 please use RxAppState version 1.1.2  
If you are using Swift 4.2 please use RxAppState version 1.4.1


## Dependencies
RxSwift 6.2 or greater
RxCocoa 6.2 or greater

## Integration
### CocoaPods
`RxAppState` is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your `Podfile`:

```ruby
pod "RxAppState"
```

If Xcode complains about Swift versions add this to the end of your Podfile:

```ruby
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '5.0'
        end
    end
end
```

### Carthage

You can use [Carthage](https://github.com/Carthage/Carthage) to install `RxAppState` by adding it to your `Cartfile`:

```
github "pixeldock/RxAppState"
```

### Swift Package Manager

You can use Swift Package Manager to install `RxAppState`:

https://swift.org/package-manager/

## Author

Jörn Schoppe,  
joern@pixeldock.com   

[![Twitter](https://img.shields.io/badge/Twitter-@pixeldock-blue.svg?style=flat)](http://twitter.com/pixeldock)
[![Blog](https://img.shields.io/badge/Blog-pixeldock-FF0066.svg?style=flat)](http://pixeldock.com/blog)


## License

RxAppState is available under the MIT license. See the LICENSE file for more info.
