platform :osx, '10.10'
use_frameworks!

def pods_for_errbody
    pod 'BuildaUtils', '~> 0.1.5'
end

def rac
    pod 'ReactiveCocoa', '4.0.2-alpha-1'
end

def also_xcode_pods
    pods_for_errbody
    pod 'XcodeServerSDK', '~> 0.4.0'
    pod 'ekgclient', '~> 0.3.0', :inhibit_warnings => true
end

def buildasaur_app_pods
    also_xcode_pods
    rac
    pod 'Ji', '1.1.2'
end

target 'Buildasaur' do
    buildasaur_app_pods
end

target 'BuildaKit' do
    buildasaur_app_pods
end

target 'BuildaKitTests' do
    also_xcode_pods
end

target 'BuildaGitServer' do
    pods_for_errbody
end

target 'BuildaGitServerTests' do
    pods_for_errbody
end

target 'BuildaHeartbeatKit' do
    also_xcode_pods
end

