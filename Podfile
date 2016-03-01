
plugin 'cocoapods-keys', {
  :project => "Buildasaur.xcodeproj",
  :keys => [
    "GitHubAPIClientId",
    "GitHubAPIClientSecret",
    "EnterpriseGitHubHostname", # e.g. git.mycompany.com
    "EnterpriseGitHubAPIPath", # e.g. git.mycompany.com/api/v1"
    "EnterpriseGitHubAPIClientId",
    "EnterpriseGitHubAPIClientSecret",
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
    # pod 'Nimble', '~> 3.0.0'
    pod 'Nimble', :git => "https://github.com/Quick/Nimble.git", :commit => "b9256b0bdecc4ef1f659b7663dcd3aab6f43fb5f"
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
    also_xcode_pods
    test_pods
end

target 'BuildaGitServer' do
    pods_for_errbody
    rac
end

target 'BuildaGitServerTests' do
    pods_for_errbody
    test_pods
    pod 'DVR', '~> 0.2.1-snap1'
end

target 'BuildaHeartbeatKit' do
    also_xcode_pods
end



