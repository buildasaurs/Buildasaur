platform :osx, '10.10'
use_frameworks!

def pods_for_errbody
	pod 'BuildaUtils', '0.1.0'
end

def rac
	pod 'ReactiveCocoa', '4.0.2-alpha-1'
end

def also_xcode_pods
	pods_for_errbody
	pod 'XcodeServerSDK', '0.3.0'
	pod 'ekgclient', '0.3.0'
end

target 'Buildasaur' do
	also_xcode_pods
	rac
end

target 'BuildaKit' do
	also_xcode_pods
	rac
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



