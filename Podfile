platform :osx, '10.10'
use_frameworks!

def pods_for_errbody
	pod 'BuildaUtils', '0.0.11'
end

def pods_for_analytics
	pod 'Tapstream', '2.9.5'
end

def also_xcode_pods
	pods_for_errbody
	pod 'XcodeServerSDK', '0.1.10'
end

target 'Buildasaur' do
	also_xcode_pods
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

target 'BuildaAnalytics' do
	pods_for_analytics
end
