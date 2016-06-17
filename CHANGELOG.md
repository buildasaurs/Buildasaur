# Change Log

## [Unreleased](https://github.com/czechboy0/buildasaur/tree/HEAD)

[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v1.0.0-b3...HEAD)

**Fixed bugs:**

- Force unwrap crash in Bot.init \(JSON contains an error\) [\#274](https://github.com/czechboy0/Buildasaur/issues/274)

**Closed issues:**

- Question: Preference for adding a service [\#279](https://github.com/czechboy0/Buildasaur/issues/279)
- Failed to access server, error: 404: for GitHub [\#278](https://github.com/czechboy0/Buildasaur/issues/278)
- Wrong project after cancel when creating new syncer [\#277](https://github.com/czechboy0/Buildasaur/issues/277)
- Private Bitbucket Repo [\#276](https://github.com/czechboy0/Buildasaur/issues/276)
- Error: Failed to post a status ... on commit [\#273](https://github.com/czechboy0/Buildasaur/issues/273)
- Repository maintenance not recognized [\#271](https://github.com/czechboy0/Buildasaur/issues/271)
- Support for cleaning up older integrations? [\#269](https://github.com/czechboy0/Buildasaur/issues/269)
- Create a Cask update fastlane action [\#229](https://github.com/czechboy0/Buildasaur/issues/229)

**Merged pull requests:**

- More throwing, less trapping, more fixes [\#281](https://github.com/czechboy0/Buildasaur/pull/281) ([czechboy0](https://github.com/czechboy0))
- Added support for repo URLs prefixed with ssh:// [\#260](https://github.com/czechboy0/Buildasaur/pull/260) ([ioveracker](https://github.com/ioveracker))
- Added ability to create syncers for tvOS projects [\#258](https://github.com/czechboy0/Buildasaur/pull/258) ([ioveracker](https://github.com/ioveracker))

## [v1.0.0-b3](https://github.com/czechboy0/buildasaur/tree/v1.0.0-b3) (2016-03-29)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v1.0.0-b2...v1.0.0-b3)

**Fixed bugs:**

- Crash when syncing Github PR from a deleted repo [\#247](https://github.com/czechboy0/Buildasaur/issues/247)
- Buildasaur doesn't extract repo name from GitHub url that does not end in ".git" [\#244](https://github.com/czechboy0/Buildasaur/issues/244)

**Closed issues:**

- Analyzer warning counts in commits and email text [\#253](https://github.com/czechboy0/Buildasaur/issues/253)
- Prebuild trigger cannot find project folder [\#252](https://github.com/czechboy0/Buildasaur/issues/252)
- Internal Server Error \(xcssecurity\): could not read password from keychain [\#245](https://github.com/czechboy0/Buildasaur/issues/245)
- Send heartbeat event when app gets sparkle-updated [\#236](https://github.com/czechboy0/Buildasaur/issues/236)
- Investigate viability of integration with Swift Package Manager/Build System [\#197](https://github.com/czechboy0/Buildasaur/issues/197)

**Merged pull requests:**

- Include Analyzer Warning count when result is Warnings [\#254](https://github.com/czechboy0/Buildasaur/pull/254) ([czechboy0](https://github.com/czechboy0))
- Spring cleaning \(fixed tests, project, updated cocoapods\) [\#250](https://github.com/czechboy0/Buildasaur/pull/250) ([czechboy0](https://github.com/czechboy0))
- Updated Swift version, crash fix [\#249](https://github.com/czechboy0/Buildasaur/pull/249) ([czechboy0](https://github.com/czechboy0))
- Buildasaur Github issue \#244 [\#246](https://github.com/czechboy0/Buildasaur/pull/246) ([lindsaylandry](https://github.com/lindsaylandry))
- Sparkle Update Event [\#241](https://github.com/czechboy0/Buildasaur/pull/241) ([czechboy0](https://github.com/czechboy0))
- Swift 2.2, dependencies upgraded [\#237](https://github.com/czechboy0/Buildasaur/pull/237) ([czechboy0](https://github.com/czechboy0))

## [v1.0.0-b2](https://github.com/czechboy0/buildasaur/tree/v1.0.0-b2) (2016-02-04)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v1.0.0-b1...v1.0.0-b2)

**Fixed bugs:**

- Clean install prints errors on startup \(migration related\) [\#227](https://github.com/czechboy0/Buildasaur/issues/227)
- Bugfix in migration [\#234](https://github.com/czechboy0/Buildasaur/pull/234) ([czechboy0](https://github.com/czechboy0))

**Closed issues:**

- Add types of used services to Heartbeat \(to better allocate time for features\) [\#219](https://github.com/czechboy0/Buildasaur/issues/219)
- Update README [\#213](https://github.com/czechboy0/Buildasaur/issues/213)
- Show on dashboard when a bot is erroring out [\#206](https://github.com/czechboy0/Buildasaur/issues/206)

**Merged pull requests:**

- Sparkle and Keychain fixes in development [\#235](https://github.com/czechboy0/Buildasaur/pull/235) ([czechboy0](https://github.com/czechboy0))
- Syncer status UI improvements [\#233](https://github.com/czechboy0/Buildasaur/pull/233) ([czechboy0](https://github.com/czechboy0))
- Added syncer types to heartbeat to know the github/bitbucket split [\#232](https://github.com/czechboy0/Buildasaur/pull/232) ([czechboy0](https://github.com/czechboy0))
- Readme improvements for 1.0 [\#231](https://github.com/czechboy0/Buildasaur/pull/231) ([czechboy0](https://github.com/czechboy0))

## [v1.0.0-b1](https://github.com/czechboy0/buildasaur/tree/v1.0.0-b1) (2016-02-03)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.8.0...v1.0.0-b1)

**Closed issues:**

- Create a Sparkle xml feed update fastlane action [\#228](https://github.com/czechboy0/Buildasaur/issues/228)
- Add pushing to Cask into the Fastfile release lane [\#191](https://github.com/czechboy0/Buildasaur/issues/191)
- Investigate opening a socket to the GitHub server [\#170](https://github.com/czechboy0/Buildasaur/issues/170)
- Bitbucket Support [\#65](https://github.com/czechboy0/Buildasaur/issues/65)
- Automatic updates [\#44](https://github.com/czechboy0/Buildasaur/issues/44)

**Merged pull requests:**

- Adding Sparkle autoupdater [\#230](https://github.com/czechboy0/Buildasaur/pull/230) ([czechboy0](https://github.com/czechboy0))
- \[WIP\] Full BitBucket Support [\#217](https://github.com/czechboy0/Buildasaur/pull/217) ([czechboy0](https://github.com/czechboy0))
- Developing 1.0 - Iris [\#214](https://github.com/czechboy0/Buildasaur/pull/214) ([czechboy0](https://github.com/czechboy0))

## [v0.8.0](https://github.com/czechboy0/buildasaur/tree/v0.8.0) (2016-01-28)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.6.5...v0.8.0)

**Fixed bugs:**

- Fix signing releases with Developer ID [\#211](https://github.com/czechboy0/Buildasaur/issues/211)

**Closed issues:**

- Extend SwiftSafe to async ops, use it to synchronize HTTP server for refresh token bottleneck [\#220](https://github.com/czechboy0/Buildasaur/issues/220)
- Put logs into a separate folder [\#202](https://github.com/czechboy0/Buildasaur/issues/202)
- Add Crashlytics [\#198](https://github.com/czechboy0/Buildasaur/issues/198)
- Introduce more state granularity when syncing [\#168](https://github.com/czechboy0/Buildasaur/issues/168)
- Split logs into multiple files  [\#142](https://github.com/czechboy0/Buildasaur/issues/142)
- Password Storage [\#137](https://github.com/czechboy0/Buildasaur/issues/137)
- Request/response caching [\#62](https://github.com/czechboy0/Buildasaur/issues/62)

**Merged pull requests:**

- BitBucket pagination [\#224](https://github.com/czechboy0/Buildasaur/pull/224) ([czechboy0](https://github.com/czechboy0))
- BitBucket posting comments [\#223](https://github.com/czechboy0/Buildasaur/pull/223) ([czechboy0](https://github.com/czechboy0))
- BitBucket refresh token flow [\#222](https://github.com/czechboy0/Buildasaur/pull/222) ([czechboy0](https://github.com/czechboy0))
- Most BitBucket entities [\#221](https://github.com/czechboy0/Buildasaur/pull/221) ([czechboy0](https://github.com/czechboy0))
- \[WIP\] BitBucket entities [\#218](https://github.com/czechboy0/Buildasaur/pull/218) ([czechboy0](https://github.com/czechboy0))
- BitBucket authentication [\#216](https://github.com/czechboy0/Buildasaur/pull/216) ([czechboy0](https://github.com/czechboy0))
- Authentication refactoring [\#215](https://github.com/czechboy0/Buildasaur/pull/215) ([czechboy0](https://github.com/czechboy0))
- Adding Crashlytics [\#210](https://github.com/czechboy0/Buildasaur/pull/210) ([czechboy0](https://github.com/czechboy0))
- Storing credentials in Keychain [\#209](https://github.com/czechboy0/Buildasaur/pull/209) ([czechboy0](https://github.com/czechboy0))
- Just moving files around... [\#207](https://github.com/czechboy0/Buildasaur/pull/207) ([czechboy0](https://github.com/czechboy0))
- Added Builda's beautiful face to the main window! [\#204](https://github.com/czechboy0/Buildasaur/pull/204) ([czechboy0](https://github.com/czechboy0))
- GitHub response caching [\#203](https://github.com/czechboy0/Buildasaur/pull/203) ([czechboy0](https://github.com/czechboy0))
- Cap log file size at 10MB [\#201](https://github.com/czechboy0/Buildasaur/pull/201) ([accatyyc](https://github.com/accatyyc))
- RAC updated to 4.RC1 [\#200](https://github.com/czechboy0/Buildasaur/pull/200) ([czechboy0](https://github.com/czechboy0))

## [v0.6.5](https://github.com/czechboy0/buildasaur/tree/v0.6.5) (2016-01-14)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.6.4...v0.6.5)

**Merged pull requests:**

- Xcode 7.3b1 API compatibility \(9\) [\#199](https://github.com/czechboy0/Buildasaur/pull/199) ([czechboy0](https://github.com/czechboy0))

## [v0.6.4](https://github.com/czechboy0/buildasaur/tree/v0.6.4) (2015-11-04)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.6.3...v0.6.4)

**Fixed bugs:**

- Selecting scheme from popup selects incorrect scheme [\#193](https://github.com/czechboy0/Buildasaur/issues/193)
- Device missing on OS X Project [\#192](https://github.com/czechboy0/Buildasaur/issues/192)

**Closed issues:**

- Sort devices by name and OS version [\#195](https://github.com/czechboy0/Buildasaur/issues/195)
- Add UI To Update Existing Build Templates [\#190](https://github.com/czechboy0/Buildasaur/issues/190)
- Add Buildasaur to homebrew cask [\#189](https://github.com/czechboy0/Buildasaur/issues/189)

**Merged pull requests:**

- Change the device sort to incorporate name and OS version. [\#196](https://github.com/czechboy0/Buildasaur/pull/196) ([hallc](https://github.com/hallc))
- Fixed incorrect scheme in build template editing screen [\#194](https://github.com/czechboy0/Buildasaur/pull/194) ([czechboy0](https://github.com/czechboy0))

## [v0.6.3](https://github.com/czechboy0/buildasaur/tree/v0.6.3) (2015-10-21)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.6.2...v0.6.3)

**Closed issues:**

- Add PR Title to Bot Name [\#187](https://github.com/czechboy0/Buildasaur/issues/187)
- Migrate away from needing checkout/blueprint files [\#186](https://github.com/czechboy0/Buildasaur/issues/186)
- Create xcscmblueprint file from an existing bot [\#173](https://github.com/czechboy0/Buildasaur/issues/173)
- Find a way to force Xcode to generate xcscmblueprint file when not present [\#165](https://github.com/czechboy0/Buildasaur/issues/165)
- The importance of keeping source control files  [\#154](https://github.com/czechboy0/Buildasaur/issues/154)
- Stash Support [\#105](https://github.com/czechboy0/Buildasaur/issues/105)

**Merged pull requests:**

- Parsing metadata information directly from git repo \(in the absence of checkout files\) [\#188](https://github.com/czechboy0/Buildasaur/pull/188) ([czechboy0](https://github.com/czechboy0))
- Refactored comment creation \(+ added tests\) [\#184](https://github.com/czechboy0/Buildasaur/pull/184) ([czechboy0](https://github.com/czechboy0))

## [v0.6.2](https://github.com/czechboy0/buildasaur/tree/v0.6.2) (2015-10-15)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.6.1...v0.6.2)

**Fixed bugs:**

- Blueprint file fails to validate [\#172](https://github.com/czechboy0/Buildasaur/issues/172)
- SSH error occurs when pushing a commit to a branch with an active PR while first build is running [\#112](https://github.com/czechboy0/Buildasaur/issues/112)

**Closed issues:**

- Option to add Buildasaur to login items [\#177](https://github.com/czechboy0/Buildasaur/issues/177)
- Ensure we're not re-posting the same comment [\#163](https://github.com/czechboy0/Buildasaur/issues/163)
- Gray out PR branches in "watched branches" [\#161](https://github.com/czechboy0/Buildasaur/issues/161)
- Add deep links to Xcode in posted GitHub comments [\#160](https://github.com/czechboy0/Buildasaur/issues/160)
- Allow Builda to be ran as a CLI tool \(no UI\) [\#100](https://github.com/czechboy0/Buildasaur/issues/100)

**Merged pull requests:**

- Handling of missing Xcode project/workspaces [\#179](https://github.com/czechboy0/Buildasaur/pull/179) ([czechboy0](https://github.com/czechboy0))
- Add Buildasaur to Login Items \(option\) [\#178](https://github.com/czechboy0/Buildasaur/pull/178) ([czechboy0](https://github.com/czechboy0))
- Deep links into Xcode from GitHub comments [\#176](https://github.com/czechboy0/Buildasaur/pull/176) ([czechboy0](https://github.com/czechboy0))
- Watched Branches: show PR numbers next to branches [\#175](https://github.com/czechboy0/Buildasaur/pull/175) ([czechboy0](https://github.com/czechboy0))

## [v0.6.1](https://github.com/czechboy0/buildasaur/tree/v0.6.1) (2015-10-14)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.6.0...v0.6.1)

**Closed issues:**

- GIT Warning [\#136](https://github.com/czechboy0/Buildasaur/issues/136)

**Merged pull requests:**

- Fixed URL caching [\#174](https://github.com/czechboy0/Buildasaur/pull/174) ([czechboy0](https://github.com/czechboy0))
- Fixed sync interval not being changed live [\#171](https://github.com/czechboy0/Buildasaur/pull/171) ([czechboy0](https://github.com/czechboy0))

## [v0.6.0](https://github.com/czechboy0/buildasaur/tree/v0.6.0) (2015-10-13)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.5.1...v0.6.0)

**Fixed bugs:**

- GitHub API request rate seems wrong [\#156](https://github.com/czechboy0/Buildasaur/issues/156)

**Closed issues:**

- nothing happens when clicking save button on Build Template Settings sheet [\#157](https://github.com/czechboy0/Buildasaur/issues/157)
- Add autostart option \(starts syncers on launch\) [\#155](https://github.com/czechboy0/Buildasaur/issues/155)
- Improve position of new windows on screen [\#153](https://github.com/czechboy0/Buildasaur/issues/153)
- Write a migrator to the new data structure in multi-repo changes [\#152](https://github.com/czechboy0/Buildasaur/issues/152)
- Xcode 7: Investigate how xcscmblueprint relates to xccheckout [\#89](https://github.com/czechboy0/Buildasaur/issues/89)
- Support multiple repositories [\#12](https://github.com/czechboy0/Buildasaur/issues/12)
- Save triggers independently of build templates \(for easy reuse\) [\#1](https://github.com/czechboy0/Buildasaur/issues/1)

**Merged pull requests:**

- fixed new window positioning [\#164](https://github.com/czechboy0/Buildasaur/pull/164) ([czechboy0](https://github.com/czechboy0))
- Multi-repo support [\#138](https://github.com/czechboy0/Buildasaur/pull/138) ([czechboy0](https://github.com/czechboy0))

## [v0.5.1](https://github.com/czechboy0/buildasaur/tree/v0.5.1) (2015-10-06)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.5.0...v0.5.1)

**Fixed bugs:**

- Buildasaur post multiple comments for the same integration [\#147](https://github.com/czechboy0/Buildasaur/issues/147)
- Schemes not detected when owned by workspace [\#144](https://github.com/czechboy0/Buildasaur/issues/144)

**Closed issues:**

- Parse workspace as proper XML [\#148](https://github.com/czechboy0/Buildasaur/issues/148)
- Can you put bots or at least triggers under source control? [\#145](https://github.com/czechboy0/Buildasaur/issues/145)
- Can't add Xcode Project/Workspace [\#140](https://github.com/czechboy0/Buildasaur/issues/140)
- Generate Settings UI Dynamically from a JSON [\#111](https://github.com/czechboy0/Buildasaur/issues/111)
- Adaptive sync interval  [\#57](https://github.com/czechboy0/Buildasaur/issues/57)

**Merged pull requests:**

- Proper workspace XML parsing [\#150](https://github.com/czechboy0/Buildasaur/pull/150) ([czechboy0](https://github.com/czechboy0))
- Fixed unrecognized schemes owned by workspace [\#149](https://github.com/czechboy0/Buildasaur/pull/149) ([czechboy0](https://github.com/czechboy0))

## [v0.5.0](https://github.com/czechboy0/buildasaur/tree/v0.5.0) (2015-09-29)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.4.0...v0.5.0)

**Fixed bugs:**

- Bots Initial Integrations Are Not Triggered [\#129](https://github.com/czechboy0/Buildasaur/issues/129)
- Can't setup using a project that was checked out via SSH [\#127](https://github.com/czechboy0/Buildasaur/issues/127)

**Closed issues:**

- Change the lttm barrier default from enabled to disabled [\#130](https://github.com/czechboy0/Buildasaur/issues/130)
- Analyzer Warnings are Not considered Errors [\#128](https://github.com/czechboy0/Buildasaur/issues/128)
- Alamofire issue when creating a .app \(crashes on startup\) [\#126](https://github.com/czechboy0/Buildasaur/issues/126)
- Improve logs [\#121](https://github.com/czechboy0/Buildasaur/issues/121)
- Investigate simplifying networking code with Alamofire [\#120](https://github.com/czechboy0/Buildasaur/issues/120)
- Give more detailed test result comments [\#87](https://github.com/czechboy0/Buildasaur/issues/87)
- Handle timing-out Simulator/Devices [\#84](https://github.com/czechboy0/Buildasaur/issues/84)
- Hook into the websocket published by xcs to update GitHub status better [\#7](https://github.com/czechboy0/Buildasaur/issues/7)

**Merged pull requests:**

- Refactored loading of checkout file, added support for xcscmblueprint file [\#141](https://github.com/czechboy0/Buildasaur/pull/141) ([czechboy0](https://github.com/czechboy0))
- Disable App Transport Security to connect to self-signed XCS [\#134](https://github.com/czechboy0/Buildasaur/pull/134) ([Brett-Best](https://github.com/Brett-Best))
- lttm barrier default changed to disabled [\#131](https://github.com/czechboy0/Buildasaur/pull/131) ([czechboy0](https://github.com/czechboy0))

## [v0.4.0](https://github.com/czechboy0/buildasaur/tree/v0.4.0) (2015-09-17)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.3.1...v0.4.0)

**Closed issues:**

- Add basic, anonymous stat reporting [\#93](https://github.com/czechboy0/Buildasaur/issues/93)

**Merged pull requests:**

- Anonymous Heartbeat Sending [\#125](https://github.com/czechboy0/Buildasaur/pull/125) ([czechboy0](https://github.com/czechboy0))

## [v0.3.1](https://github.com/czechboy0/buildasaur/tree/v0.3.1) (2015-09-17)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.3...v0.3.1)

**Fixed bugs:**

- Build Template UI - Testing Devices Not Shown Bug [\#124](https://github.com/czechboy0/Buildasaur/pull/124) ([czechboy0](https://github.com/czechboy0))

**Closed issues:**

- Testing devices don't show up when editing a build template [\#123](https://github.com/czechboy0/Buildasaur/issues/123)

## [v0.3](https://github.com/czechboy0/buildasaur/tree/v0.3) (2015-09-10)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.3-beta5...v0.3)

**Closed issues:**

- what does LTTM mean? [\#117](https://github.com/czechboy0/Buildasaur/issues/117)

**Merged pull requests:**

- Swift 2! [\#122](https://github.com/czechboy0/Buildasaur/pull/122) ([czechboy0](https://github.com/czechboy0))

## [v0.3-beta5](https://github.com/czechboy0/buildasaur/tree/v0.3-beta5) (2015-08-25)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.3-beta4...v0.3-beta5)

**Closed issues:**

- Redundant integration step reporting [\#113](https://github.com/czechboy0/Buildasaur/issues/113)

**Merged pull requests:**

- Xcode 7 Beta 6 fixes [\#116](https://github.com/czechboy0/Buildasaur/pull/116) ([czechboy0](https://github.com/czechboy0))
- Remove "Buildasaur:" from GitHub build status messages [\#115](https://github.com/czechboy0/Buildasaur/pull/115) ([accatyyc](https://github.com/accatyyc))

## [v0.3-beta4](https://github.com/czechboy0/buildasaur/tree/v0.3-beta4) (2015-07-25)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.3-beta3...v0.3-beta4)

**Closed issues:**

- 0.29: The server SSH fingerprint failed to verify. [\#107](https://github.com/czechboy0/Buildasaur/issues/107)

**Merged pull requests:**

- Add Slack info [\#110](https://github.com/czechboy0/Buildasaur/pull/110) ([cojoj](https://github.com/cojoj))
- xcode 7 beta 4 fixes [\#108](https://github.com/czechboy0/Buildasaur/pull/108) ([czechboy0](https://github.com/czechboy0))
- Singular/Plural Noun Fixes [\#104](https://github.com/czechboy0/Buildasaur/pull/104) ([czechboy0](https://github.com/czechboy0))
- Update README.md [\#103](https://github.com/czechboy0/Buildasaur/pull/103) ([czechboy0](https://github.com/czechboy0))

## [v0.3-beta3](https://github.com/czechboy0/buildasaur/tree/v0.3-beta3) (2015-07-19)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.3-beta2...v0.3-beta3)

**Fixed bugs:**

- Clean testing device ids when destination is changed [\#85](https://github.com/czechboy0/Buildasaur/issues/85)
- Incorrect comment info  [\#82](https://github.com/czechboy0/Buildasaur/issues/82)

**Closed issues:**

- Save Project Name to Build Templates and only show filtered for specific project [\#96](https://github.com/czechboy0/Buildasaur/issues/96)
- Create an object for TestHierarchy [\#92](https://github.com/czechboy0/Buildasaur/issues/92)
- Report code coverage in github comments [\#75](https://github.com/czechboy0/Buildasaur/issues/75)

**Merged pull requests:**

- Moved logging to BuildaKit [\#102](https://github.com/czechboy0/Buildasaur/pull/102) ([czechboy0](https://github.com/czechboy0))
- Pulled out logic into BuildaKit, split BuildaUtils into a separate project [\#101](https://github.com/czechboy0/Buildasaur/pull/101) ([czechboy0](https://github.com/czechboy0))
- Filter Build Templates by Project [\#98](https://github.com/czechboy0/Buildasaur/pull/98) ([czechboy0](https://github.com/czechboy0))
- Clean testing device ids when scheme/device filter type is changed [\#97](https://github.com/czechboy0/Buildasaur/pull/97) ([czechboy0](https://github.com/czechboy0))
- Update README.md [\#95](https://github.com/czechboy0/Buildasaur/pull/95) ([czechboy0](https://github.com/czechboy0))
- Adding Code Coverage and Test Number changes to comments [\#91](https://github.com/czechboy0/Buildasaur/pull/91) ([czechboy0](https://github.com/czechboy0))

## [v0.3-beta2](https://github.com/czechboy0/buildasaur/tree/v0.3-beta2) (2015-07-15)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.3-beta1...v0.3-beta2)

**Merged pull requests:**

- Fixed generic array parameter name changed in Xcode 7 beta 3 [\#90](https://github.com/czechboy0/Buildasaur/pull/90) ([czechboy0](https://github.com/czechboy0))
- Update master -\> gladiolus [\#88](https://github.com/czechboy0/Buildasaur/pull/88) ([czechboy0](https://github.com/czechboy0))
- sync master [\#86](https://github.com/czechboy0/Buildasaur/pull/86) ([czechboy0](https://github.com/czechboy0))
- New App Icon and small fixes. [\#74](https://github.com/czechboy0/Buildasaur/pull/74) ([Higgcz](https://github.com/Higgcz))

## [v0.3-beta1](https://github.com/czechboy0/buildasaur/tree/v0.3-beta1) (2015-07-02)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.2.9...v0.3-beta1)

**Fixed bugs:**

- It is not possible to edit trigger scripts inline [\#58](https://github.com/czechboy0/Buildasaur/issues/58)

**Closed issues:**

- Infer and automatically filter devices based on target type [\#77](https://github.com/czechboy0/Buildasaur/issues/77)
- Migrate to Swift 2 [\#76](https://github.com/czechboy0/Buildasaur/issues/76)
- Update UI to support multiple repositories [\#72](https://github.com/czechboy0/Buildasaur/issues/72)
- Migrate to XcodeServerSDK [\#71](https://github.com/czechboy0/Buildasaur/issues/71)
- Buildasaur immediately crashes after being started [\#70](https://github.com/czechboy0/Buildasaur/issues/70)
- Xcode 7 support  [\#69](https://github.com/czechboy0/Buildasaur/issues/69)
- Leaving for WWDC, back in mid June. [\#67](https://github.com/czechboy0/Buildasaur/issues/67)
- Identify bots not by name but by a custom key  [\#66](https://github.com/czechboy0/Buildasaur/issues/66)
- Extract BuildaCiServer [\#63](https://github.com/czechboy0/Buildasaur/issues/63)
- Autocreation Test [\#55](https://github.com/czechboy0/Buildasaur/issues/55)
- Autocreation Test [\#54](https://github.com/czechboy0/Buildasaur/issues/54)
- Add a Readme badge for "Build Passing" [\#33](https://github.com/czechboy0/Buildasaur/issues/33)
- Update branch's commit statuses based on a non-PR bot [\#18](https://github.com/czechboy0/Buildasaur/issues/18)

**Merged pull requests:**

- Xcode 7 compatibility [\#78](https://github.com/czechboy0/Buildasaur/pull/78) ([czechboy0](https://github.com/czechboy0))
- Migrating to XcodeServerSDK [\#73](https://github.com/czechboy0/Buildasaur/pull/73) ([czechboy0](https://github.com/czechboy0))
- Fix status bar icon being invisible in dark mode [\#68](https://github.com/czechboy0/Buildasaur/pull/68) ([accatyyc](https://github.com/accatyyc))
- Adding Branch Watching [\#61](https://github.com/czechboy0/Buildasaur/pull/61) ([czechboy0](https://github.com/czechboy0))
- Trigger VC: Enter now inserts a newline in the script body field [\#59](https://github.com/czechboy0/Buildasaur/pull/59) ([czechboy0](https://github.com/czechboy0))
- Issue endpoints support [\#56](https://github.com/czechboy0/Buildasaur/pull/56) ([czechboy0](https://github.com/czechboy0))
- Added more Syncer tests [\#52](https://github.com/czechboy0/Buildasaur/pull/52) ([czechboy0](https://github.com/czechboy0))
- Initial refactor of syncer [\#51](https://github.com/czechboy0/Buildasaur/pull/51) ([czechboy0](https://github.com/czechboy0))
- Add a build status badge [\#50](https://github.com/czechboy0/Buildasaur/pull/50) ([czechboy0](https://github.com/czechboy0))

## [v0.2.9](https://github.com/czechboy0/buildasaur/tree/v0.2.9) (2015-05-14)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.2.8...v0.2.9)

**Closed issues:**

- Add a menu icon for Buildasaur and make it run in the background [\#26](https://github.com/czechboy0/Buildasaur/issues/26)

**Merged pull requests:**

- Menu bar, running in the background [\#48](https://github.com/czechboy0/Buildasaur/pull/48) ([czechboy0](https://github.com/czechboy0))

## [v0.2.8](https://github.com/czechboy0/buildasaur/tree/v0.2.8) (2015-05-14)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.2.7...v0.2.8)

**Fixed bugs:**

- Test cancelling an integration during checkout, doesn't it integrate again? Fix [\#46](https://github.com/czechboy0/Buildasaur/issues/46)

**Merged pull requests:**

- Fix for canceled integrations during Checkout [\#47](https://github.com/czechboy0/Buildasaur/pull/47) ([czechboy0](https://github.com/czechboy0))

## [v0.2.7](https://github.com/czechboy0/buildasaur/tree/v0.2.7) (2015-05-13)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.2.6...v0.2.7)

**Fixed bugs:**

- Build Template Settings has no schemes in dropdown [\#38](https://github.com/czechboy0/Buildasaur/issues/38)
- Support for SSH passphrases [\#27](https://github.com/czechboy0/Buildasaur/issues/27)

**Closed issues:**

- Report build run duration in status/comment [\#31](https://github.com/czechboy0/Buildasaur/issues/31)
- Validate SSH keys during project setup validation [\#30](https://github.com/czechboy0/Buildasaur/issues/30)
- A way to disable automatic comments [\#28](https://github.com/czechboy0/Buildasaur/issues/28)
- Add Blueprint validation with xcsbridge source-control [\#25](https://github.com/czechboy0/Buildasaur/issues/25)

**Merged pull requests:**

- Option to disable posting status comments [\#43](https://github.com/czechboy0/Buildasaur/pull/43) ([czechboy0](https://github.com/czechboy0))
- SSH Passphrase Support + Better SSH Validation [\#42](https://github.com/czechboy0/Buildasaur/pull/42) ([czechboy0](https://github.com/czechboy0))
- Verify Git version \>= 2.3 [\#41](https://github.com/czechboy0/Buildasaur/pull/41) ([czechboy0](https://github.com/czechboy0))
- SSH Key Validation in onboarding [\#40](https://github.com/czechboy0/Buildasaur/pull/40) ([czechboy0](https://github.com/czechboy0))
- Shared schemes in workspace fix [\#39](https://github.com/czechboy0/Buildasaur/pull/39) ([czechboy0](https://github.com/czechboy0))
- Add Football Addicts to PROJECTS\_USING\_BUILDASAUR.md [\#37](https://github.com/czechboy0/Buildasaur/pull/37) ([accatyyc](https://github.com/accatyyc))
- Create PROJECTS\_USING\_BUILDASAUR.md [\#36](https://github.com/czechboy0/Buildasaur/pull/36) ([czechboy0](https://github.com/czechboy0))
- Integration duration in status comments [\#35](https://github.com/czechboy0/Buildasaur/pull/35) ([czechboy0](https://github.com/czechboy0))
- Simplify 'findCheckoutUrl' method [\#32](https://github.com/czechboy0/Buildasaur/pull/32) ([garnett](https://github.com/garnett))

## [v0.2.6](https://github.com/czechboy0/buildasaur/tree/v0.2.6) (2015-05-04)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.2.5...v0.2.6)

**Fixed bugs:**

- Add support for PRs across forks [\#23](https://github.com/czechboy0/Buildasaur/issues/23)

**Merged pull requests:**

- added support for cross-fork pull requests [\#24](https://github.com/czechboy0/Buildasaur/pull/24) ([czechboy0](https://github.com/czechboy0))
- Fixed repo permissions check [\#22](https://github.com/czechboy0/Buildasaur/pull/22) ([mdio](https://github.com/mdio))

## [v0.2.5](https://github.com/czechboy0/buildasaur/tree/v0.2.5) (2015-05-03)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.2.4...v0.2.5)

**Fixed bugs:**

- Check if supplied GitHub account has read and write access to the repository [\#15](https://github.com/czechboy0/Buildasaur/issues/15)
- Disable URL caching to always get the latest data from GitHub \(comments, statuses\) [\#10](https://github.com/czechboy0/Buildasaur/issues/10)

**Closed issues:**

- Add GitHub rate limit monitoring and smart interval estimation [\#17](https://github.com/czechboy0/Buildasaur/issues/17)
- Find out whether GitHub rate limit is per user or per token [\#13](https://github.com/czechboy0/Buildasaur/issues/13)
- Allow automatic start of builds after pull request has been opened [\#11](https://github.com/czechboy0/Buildasaur/issues/11)
- Show current step's string in the commit status \(building/testing/archiving,...\) [\#3](https://github.com/czechboy0/Buildasaur/issues/3)

**Merged pull requests:**

- added support for optional lttm [\#21](https://github.com/czechboy0/Buildasaur/pull/21) ([czechboy0](https://github.com/czechboy0))
- GitHub Rate Limiting in the UI now [\#20](https://github.com/czechboy0/Buildasaur/pull/20) ([czechboy0](https://github.com/czechboy0))
- Improved error handling, GitHub rate limiting in the log [\#19](https://github.com/czechboy0/Buildasaur/pull/19) ([czechboy0](https://github.com/czechboy0))
- Added running integration's current step into github status [\#16](https://github.com/czechboy0/Buildasaur/pull/16) ([czechboy0](https://github.com/czechboy0))
- Added note about r/w repository access to README.md [\#14](https://github.com/czechboy0/Buildasaur/pull/14) ([mdio](https://github.com/mdio))

## [v0.2.4](https://github.com/czechboy0/buildasaur/tree/v0.2.4) (2015-04-26)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.2.3...v0.2.4)

## [v0.2.3](https://github.com/czechboy0/buildasaur/tree/v0.2.3) (2015-04-12)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/v0.2.2...v0.2.3)

**Closed issues:**

- Add logging into a file [\#5](https://github.com/czechboy0/Buildasaur/issues/5)

## [v0.2.2](https://github.com/czechboy0/buildasaur/tree/v0.2.2) (2015-04-12)
[Full Changelog](https://github.com/czechboy0/buildasaur/compare/0.2.1...v0.2.2)

**Merged pull requests:**

- Logging into file and console [\#6](https://github.com/czechboy0/Buildasaur/pull/6) ([czechboy0](https://github.com/czechboy0))

## [0.2.1](https://github.com/czechboy0/buildasaur/tree/0.2.1) (2015-04-12)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*