Buildasaur
==========

[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](http://en.wikipedia.org/wiki/MIT_License)
[![Latest Buildasaur Release](https://img.shields.io/github/release/czechboy0/buildasaur.svg)](https://github.com/czechboy0/Buildasaur/releases/latest)

![](https://raw.githubusercontent.com/czechboy0/Buildasaur/master/Buildasaur/Images.xcassets/AppIcon.appiconset/builda_icon%40128x.png)

Free, local and automatic testing of GitHub Pull Requests with Xcode Bots. Keep your team productive and safe. Get up and running in minutes.

Getting Buildasaur
------------------
You have multiple options of getting started with Buildasaur, from source code to downloading the App.
- get the app for the [latest release](https://github.com/czechboy0/Buildasaur/releases/latest)
- check out code and build and run in Xcode

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
    + Click Done, which validates the settings and GitHub access
- In the bottom part, choose the sync interval (default is 1 minute, which works pretty well, don't decrease it too much, GitHub rate-limits access)
- If both Server and Project configs say *Verified access, all is well*, click **Start** to start syncing your pull requests with bots.

![](https://raw.githubusercontent.com/czechboy0/Buildasaur/master/Meta/builda_screenshot.png)

Default workflow
----------------
The default workflow is as follows:
- a Pull Request is created by an author, Builda creates an inactive Bot
- when someone comments "lttm" (looks testable to me) in the Pull Request conversation, Builda activates the bot, runs tests on it and reports back to GitHub with the result, by changing the status and posting a comment
- the "lttm" barrier is so that reviewers have a chance to go back and forth with the author before they are both happy with the code, at which point it makes sense to test it
- if you require a different workflow, create an issue and we'll figure something out

Manual Bot Management
---------------------
In addition to automatic bot management with syncers, you can create bots from an existing Build Template and a branch by clicking *Manual Bot Management* when your syncer is setup. This is useful for creating one-off bots based on e.g. release branches with a different Build Template than you use for PRs.

Contributing
------------
Please create an issue with a description of a problem or a pull request with a fix. I'll see what I can do.

License
-------
MIT


Author
------
Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)
