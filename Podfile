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
	pod 'XcodeServerSDK', '~> 0.3.5'
	pod 'ekgclient', '~> 0.3.0', :inhibit_warnings => true
end

target 'Buildasaur' do
	also_xcode_pods
	rac
end

target 'BuildaKit' do
	also_xcode_pods
	rac
	pod 'Ji', '1.1.2'
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

post_install do |installer|
    installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
        configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
end

