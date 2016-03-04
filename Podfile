
plugin 'cocoapods-keys', {
  :project => "Buildasaur.xcodeproj",
  :keys => [
    "GitHubAPIClientId",
    "GitHubAPIClientSecret",
    "BitBucketAPIClientId",
    "BitBucketAPIClientSecret"
]}

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/czechboy0/Podspecs.git'

platform :osx, '10.11'
use_frameworks!
inhibit_all_warnings!

def pods_for_errbody
    pod 'BuildaUtils', '~> 0.2.7'
end

def rac
    pod 'ReactiveCocoa', '~> 4.0.1'
end

def also_xcode_pods
    pods_for_errbody
    pod 'XcodeServerSDK', '~> 0.5.7'
    pod 'ekgclient', '~> 0.3.2'
end

def buildasaur_app_pods
    also_xcode_pods
    rac
    pod 'Ji', '~> 1.2.0'
    pod 'CryptoSwift'
    pod 'Sparkle'
    pod 'KeychainAccess'
end

def test_pods
    pod 'Nimble', :git => "https://github.com/Quick/Nimble.git", :commit => "1730543fcd8b7d7258a3270bb6d3118921d46f9d"
    pod 'DVR', '~> 0.2.1-snap1'
end

target 'Buildasaur' do
    buildasaur_app_pods
    pod 'Crashlytics'
    pod 'OAuthSwift'
end

target 'BuildaKit' do
    buildasaur_app_pods
end

target 'BuildaKitTests' do
    buildasaur_app_pods
    test_pods
end

target 'BuildaGitServer' do
    pods_for_errbody
    rac
end

target 'BuildaGitServerTests' do
    buildasaur_app_pods
    test_pods
end

target 'BuildaHeartbeatKit' do
    also_xcode_pods
end



