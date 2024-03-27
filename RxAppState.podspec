Pod::Spec.new do |s|
s.name             = "RxAppState"
s.version          = "1.8.1"
s.swift_versions   = ['5.0']
s.summary          = "Handy RxSwift extensions to observe your app's state and view controllers' view-related notifications"
s.description      = <<-DESC
Transform the state of your App and UIViewController's view-related notifications into RxSwift Observables. Including convenience Observables for common scenarios.
DESC
s.homepage         = "https://github.com/pixeldock/RxAppState"
s.license          = 'MIT'
s.author           = { "Jörn Schoppe" => "joern@pixeldock.com" }
s.source           = { :git => "https://github.com/pixeldock/RxAppState.git", :tag => s.version.to_s }
#s.social_media_url = 'https://twitter.com/pixeldock'

s.ios.deployment_target = '13.0'
s.tvos.deployment_target = '13.0'
s.requires_arc = true

s.source_files = 'Pod/Classes/**/*'

s.frameworks = 'Foundation'
s.dependency 'RxSwift', '~> 6.2'
s.dependency 'RxCocoa', '~> 6.2'

end
