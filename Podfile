platform :osx, '10.10'
use_frameworks!

# Allows per-dev overrides
local_podfile = "Podfile.local"
if File.exist? local_podfile

	eval(File.open(local_podfile).read) 

else

	xcs_name = 'XcodeServerSDK'
	xcs_repo = 'git@github.com:czechboy0/XcodeServerSDK.git'
	xcs_branch = 'buildasaur'

	target 'BuildaUtils' do
	pod xcs_name, :git => xcs_repo, :branch => xcs_branch
	end

	target 'BuildaGitServer' do
	pod xcs_name, :git => xcs_repo, :branch => xcs_branch
	end

	target 'Buildasaur' do
	pod xcs_name, :git => xcs_repo, :branch => xcs_branch
	end

	target 'BuildaGitServerTests' do
	pod xcs_name, :git => xcs_repo, :branch => xcs_branch
	end

	target 'BuildasaurTests' do
	pod xcs_name, :git => xcs_repo, :branch => xcs_branch
	end

	target 'BuildaUtilsTests' do
	pod xcs_name, :git => xcs_repo, :branch => xcs_branch
	end

end


