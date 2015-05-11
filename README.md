Buildasaur
==========

[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Buildasaur](https://img.shields.io/badge/twitter-Buildasaur-green.svg)](http://twitter.com/buildasaur)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)

[![Stars](https://img.shields.io/github/stars/badges/shields.svg)]()
[![Forks](https://img.shields.io/github/forks/badges/shields.svg)]()
[![Issues](https://img.shields.io/github/issues-raw/badges/shields.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](http://en.wikipedia.org/wiki/MIT_License)
[![Latest Buildasaur Release](https://img.shields.io/github/release/czechboy0/buildasaur.svg)](https://github.com/czechboy0/Buildasaur/releases/latest)

![](https://raw.githubusercontent.com/czechboy0/Buildasaur/master/Buildasaur/Images.xcassets/AppIcon.appiconset/builda_icon%40128x.png)

Free, local and automatic testing of GitHub Pull Requests with Xcode Bots. Keep your team productive and safe. Get up and running in minutes. (Follow Builda [on Twitter](http://twitter.com/buildasaur) for infrequent updates.)

**Thinking of trying Buildasaur**? Check out the list of [teams and projects](./PROJECTS_USING_BUILDASAUR.md) already using it.<br>
**Already using Buildasaur**? Please consider [adding yourself](./PROJECTS_USING_BUILDASAUR.md)!

Getting Buildasaur
------------------
You have multiple options of getting started with Buildasaur, from source code to downloading the App.
- get the app for the [latest release](https://github.com/czechboy0/Buildasaur/releases/latest)
- check out code and build and run in Xcode (requires Xcode 6.3 with Swift 1.2, thus OS X 10.10.3)

Installation Steps
------------------
- Install Xcode 6+, Xcode Server 4+ and have a GitHub repo credentials ready

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
    + Make sure that your account has read and write access to the GitHub repository (Buildasaur needs to be able to read Pull Requests, read PR comments, add a PR comment, read commit statuses, add a commit status)
    + Click Done, which validates the settings and GitHub access
- In the bottom part, choose the sync interval (default is now 15 seconds, which works pretty well, don't decrease it too much, GitHub rate-limits access to 5000 requests per hour, when authenticated and only 60 when unauthenticated)
- If both Server and Project configs say *Verified access, all is well*, click **Start** to start syncing your pull requests with bots.

![](https://raw.githubusercontent.com/czechboy0/Buildasaur/master/Meta/builda_screenshot.png)

Default workflow
----------------
The default workflow is as follows:
- a Pull Request is created by the author, Builda creates a bot
- if the "lttm" barrier (see below) is disabled, an integration is started immediately. if the "lttm" barrier is enabled, Builda waits until someone comments "lttm" in the Pull Request conversation (the "lttm" barrier is **enabled** by default, can be disabled in the UI)
- an integration is performed on the PR's branch
- result of the integration is reported back to GitHub by changing the status of the latest commit of the branch and posting a comment in the PR conversation
- if any additional commits are pushed, another integration gets performed and reported back
- when a PR is closed, the bot gets deleted
- if you require a different workflow, create an issue and we'll figure something out

The "lttm" barrier
------------------
- an optional extra step in the workflow (**enabled** by default)
- instead of integrating immediately after a PR is created, the reviewer first has a chance to look at the code and request any fixes of the code from the author
- when the reviewer is happy with the code visually, she comments "lttm" in the PR and the bot is activated and performs and integration on the code
- from that point on, if any additional commits are pushed, they get integrated as with the basic workflow

Manual Bot Management
---------------------
In addition to automatic bot management with syncers, you can create bots from an existing Build Template and a branch by clicking *Manual Bot Management* when your syncer is setup. This is useful for creating one-off bots based on e.g. release branches with a different Build Template than you use for PRs.

Troubleshooting
---------------
In case Builda crashes (God forbid), you can find crash logs at `~/Library/Logs/DiagnosticReports/Buildasaur-*`. Please let me know if that happens and I'll take a look. Also, Builda logs (pretty verbosely) to `~/Library/Application Support/Buildasaur/Builda.log`, so this is another place to watch in case of any problems.

Contributing
------------
Please create an issue with a description of a problem or a pull request with a fix. I'll see what I can do ;-)

Xcode Server Reverse Engineering
--------------------------------
If you're feeling brave and would like to dig into how Xcode Server works under the hood, you might find this article I wrote useful: [Under the Hood of Xcode Server](http://honzadvorsky.com/blog/2015/5/4/under-the-hood-of-xcode-server). Recommended reading if you want to extend Buildasaur to take a greater advantage of Xcode Server (there are still a plenty of unused APIs.)

If you end up modifying any of the files mentioned above, in order for Xcode Server to reload them, you need to go to OS X Server, to the Xcode section and with the giant green button turn it off and back on. This restarts all the tasks and reloads source files from disk.

License
-------
MIT

Author
------
Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)
