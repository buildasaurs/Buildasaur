platform :osx, '10.10'
use_frameworks!

xcs_name = 'XcodeServerSDK'
xcs_tag = '0.1.5'

b_utils = 'BuildaUtils'
b_tag = '0.0.4'

target 'BuildaGitServer' do
pod b_utils, b_tag
end

target 'BuildaGitServerTests' do
pod b_utils, b_tag
end

target 'Buildasaur' do
pod xcs_name, xcs_tag
pod b_utils, b_tag
end

target 'BuildasaurTests' do
pod xcs_name, xcs_tag
pod b_utils, b_tag
end


