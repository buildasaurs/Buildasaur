Buildasaur
==========

[![satellite badge](https://stlt.herokuapp.com/v1/badge/czechboy0/buildasaur/master)](https://github.com/czechboy0/buildasaur/branches)
[![Latest Buildasaur Release](https://img.shields.io/github/release/czechboy0/buildasaur.svg)](https://github.com/czechboy0/Buildasaur/releases/latest)
![Swift Version](https://img.shields.io/badge/Swift-2-green.svg)

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](http://en.wikipedia.org/wiki/MIT_License)
[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Buildasaur](https://img.shields.io/badge/twitter-Buildasaur-green.svg)](http://twitter.com/buildasaur)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)

![](https://raw.githubusercontent.com/czechboy0/Buildasaur/master/Buildasaur/Images.xcassets/AppIcon.appiconset/Icon_128@2x.png)

Free, local and automatic testing of GitHub Pull Requests with Xcode Bots. Keep your team productive and safe. Get up and running in minutes. (Follow Builda [on Twitter](http://twitter.com/buildasaur) for infrequent updates.)

**Get the latest [Xcode 7 release](https://github.com/czechboy0/Buildasaur/releases) (not backwards compatible). If you'd like Xcode 6 support, download version [0.2.9](https://github.com/czechboy0/Buildasaur/releases/tag/v0.2.9).**

:thought_balloon: **Thinking of trying Buildasaur?** Check out the list of [teams and projects](./PROJECTS_USING_BUILDASAUR.md) already using it.<br>
:arrows_counterclockwise: **Already using Buildasaur?** Please consider [adding yourself](./PROJECTS_USING_BUILDASAUR.md) to our success stories!<br>
:gift_heart: **Want to contribute?** Take a look at [issues with the label "up-for-grabs"](https://github.com/czechboy0/Buildasaur/labels/up-for-grabs), comment on the issue that you're working on it and let's improve Buildasaur together!

:mortar_board: Getting Started With Xcode Server 
---------------------------------
To find out how to set up Xcode Server on your Mac in minutes (and more), check out my [series of tutorials](http://honzadvorsky.com/pages/xcode_server_tutorials/).

Looking for Xcode Server SDK?
----------------
The code that makes talking to Xcode Server easy lives in a separate project: [XcodeServerSDK](https://github.com/czechboy0/XcodeServerSDK). Buildasaur is just one app that uses this SDK, but now you can build your own!

:nut_and_bolt: Configurable
------------
Buildasaur was designed to be easy to setup, while still giving you all the customization you need. By choosing the right defaults, most projects can get Buildasaur setup in minutes, start it and never have to worry about it again.

![](https://raw.githubusercontent.com/czechboy0/Buildasaur/master/Meta/builda_screenshot.png)

:eyes: Glanceable
----------
Buildasaur runs as a background Mac app, its configuration window goes away when you don't need it. This gives you a chance to quickly peek at the status of your syncers from the menu bar.

![](https://raw.githubusercontent.com/czechboy0/Buildasaur/master/Meta/menu_bar.png)

:octocat: Getting Buildasaur
------------------
You have multiple options of getting started with Buildasaur, from source code to downloading the App.
- get the .app of the [latest release](https://github.com/czechboy0/Buildasaur/releases/latest)
- starting with version 0.2.8, release .app is always signed with my [Developer ID](https://developer.apple.com/developer-id/) (Jan Dvorsky), so that you can be sure you're really launching an official release. Feel free to run Buildasaur yourself from code, just be aware that you will get a warning from OS X if you have [Gatekeeper](http://en.wikipedia.org/wiki/Gatekeeper_(OS_X)) enabled.
- check out code and build and run in Xcode (requires Xcode 7 with Swift 2, thus OS X 10.10.5)

:white_check_mark: Installation Steps
------------------
- Install Xcode 7, Xcode Server 5 and have your GitHub repo credentials ready

**Xcode Server Setup**
- Open Server.app, go to Services -> Xcode and add select your Xcode
- after the setup finishes, enable the service with the giant switch on the top right

**GitHub Setup**
- go to GitHub.com and when you're signed in, go to Settings -> Applications -> Personal access tokens -> Generate new token
- leave the default rights and copy the token

**Buildasaur Setup**
- Checkout your repo locally over SSH
- Launch Buildasaur (see [Getting Buildasaur](https://github.com/czechboy0/Buildasaur#getting-buildasaur
) for instructions)
- Click *Add your Xcode Server*
    + Fill in the IP address/host name of your Xcode server (127.0.0.1 if on the same machine)
    + Fill in the username and password if only some users can create bots
    + Click Done, which validates the credentials
- Click *Add your Xcode Project* and select the Xcode project or workspace that you want to test
    + Click on *Pick a template to build*, which will guide you through setting up of a new template
    + Paste your GitHub token
    + Select the path to your SSH keys
    + (Optional) Fill in your SSH key passphrase
    + Make sure that your account has read and write access to the GitHub repository (Buildasaur needs to be able to read Pull Requests, read PR comments, add a PR comment, read commit statuses, add a commit status)
    + Click Done, which validates the settings, SSH access and GitHub access
- In the bottom part, choose the sync interval (default is now 15 seconds, which works pretty well, don't decrease it too much, GitHub rate-limits access to 5000 requests per hour)
- If both Server and Project configs say *Verified access, all is well*, click **Start** to start syncing your pull requests with bots.

:arrows_clockwise: Default workflow
----------------
The default workflow is as follows:
- a Pull Request is created by the author, Builda creates a bot
- if the "lttm" barrier (see below) is disabled, an integration is started immediately. if the "lttm" barrier is enabled, Builda waits until someone comments "lttm" in the Pull Request conversation (the "lttm" barrier is **enabled** by default, can be disabled in the UI)
- an integration is performed on the PR's branch
- result of the integration is reported back to GitHub by changing the status of the latest commit of the branch and posting a comment in the PR conversation (optional, enabled by default)
- if any additional commits are pushed, another integration gets performed and reported back
- when a PR is closed, the bot gets deleted
- if you require a different workflow, create an issue and we'll figure something out

:unlock: The "lttm" barrier
------------------
- "Looks Testable To Me"
- an optional extra step in the workflow (**enabled** by default)
- instead of integrating immediately after a PR is created, the reviewer first has a chance to look at the code and request any fixes of the code from the author
- when the reviewer is happy with the code visually, she comments "lttm" in the PR and the bot is activated and performs an integration of the code
- from that point on, if any additional commits are pushed, they get integrated as with the basic workflow

:envelope: Posting Status Comments
-----------------------
- Builda can (and by default does) post a comment into the PR conversation when an integration finishes

![](https://raw.githubusercontent.com/czechboy0/Buildasaur/master/Meta/comment.png)

- this can be controlled in the UI with the toggle named "Post Status Comments"

:pencil2: Manual Bot Management
---------------------
In addition to automatic bot management with syncers, you can create bots from an existing Build Template and a branch by clicking *Manual Bot Management* when your syncer is setup. This is useful for creating one-off bots based on e.g. release branches with a different Build Template than you use for PRs.

:heartpulse: Heartbeat
---------------
In order to understand how many Buildasaurs are running out there, which helps me to decide how much free time I should dedicate to this project, one anonymous heartbeat event is sent from Buildasaur every 24 hours (and one when Buildasaur is launched). There is **absolutely no information** about the projects being synced with Buildasaur (I don't care about that), the event just sends a randomly generated identifier (to discern different Buildasaur instances), the uptime of Buildasaur (to potentially detect crashes) and the number of running syncers (for when we have multi-repo support).

I wrote the server storing this data myself - and [it's open source](https://github.com/czechboy0/ekg), so feel free to take a peek yourself at how that's done. And take a look [here](https://github.com/czechboy0/ekgclient/blob/master/ekgclient/Event.swift#L39) to see exactly what data is being sent.

If, despite absolutely no identifiable data is being sent, you still aren't comfortable allowing Buildasaur send its heartbeat, add `{ "heartbeat_opt_out" = true }` to `~/Library/Application Support/Buildasaur/Config.json`. But please don't, because that will make me think fewer people are in fact using Buildasaur, which might just lead to me spending less time on it. Thanks! :)

:warning: Troubleshooting
---------------
In case Builda crashes, you can find crash logs at `~/Library/Logs/DiagnosticReports/Buildasaur-*`. Please let me know if that happens and I'll take a look. Also, Builda logs (pretty verbosely) to `~/Library/Application Support/Buildasaur/Builda.log`, so this is another place to watch in case of any problems.

:gift_heart: Contributing
------------
Please create an issue with a description of a problem or a pull request with a fix. Or, if you just want to help out, take a look at [issues with the label "up-for-grabs"](https://github.com/czechboy0/Buildasaur/labels/up-for-grabs), comment on the issue that you're working on it and let's improve Buildasaur together! 

:speech_balloon: Get in touch
------------

For things like general problems/ideas please report an **issue**, so anyone can see them and relate to them in the future. It's realy important for Open Source projects like this!
If your problem requires a deep discussion or you have a great idea and you really want to share it with someone before opening an issue you can join the official [Buildasaurs](https://github.com/buildasaurs) **Slack team**! (To do so, ping [@czechboy0](https://twitter.com/czechboy0) on Twitter and have your e-mail address ready :e-mail:)

:squirrel: Xcode Server Reverse Engineering
--------------------------------
If you're feeling brave and would like to dig into how Xcode Server works under the hood, you might find this article I wrote useful: [Under the Hood of Xcode Server](http://honzadvorsky.com/blog/2015/5/4/under-the-hood-of-xcode-server). Recommended reading if you want to extend Buildasaur to take a greater advantage of Xcode Server (there are still a plenty of unused APIs.)

I also write about [working on Buildasaur](http://honzadvorsky.com/?tag=buildasaur), its challenges, interesting problems and failures on [my blog](http://honzadvorsky.com/). 

:v: License
-------
MIT

:+1: Special Thanks
---
- Vojta Micka ([@higgcz](https://twitter.com/higgcz)) for our great new logo!

:alien: Author
------
Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)
