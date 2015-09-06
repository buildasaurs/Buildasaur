platform :osx, '10.10'
use_frameworks!

def pods_for_errbody
	pod 'BuildaUtils', '0.0.11'
	pod 'hit', '0.3'
end

def ui
	pod 'RxSwift', '2.0-alpha.1'
end

def also_xcode_pods
	pods_for_errbody
	pod 'XcodeServerSDK', '0.2.1'
end

target 'Buildasaur' do
	also_xcode_pods
	ui
end

target 'BuildaKit' do
	also_xcode_pods
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



