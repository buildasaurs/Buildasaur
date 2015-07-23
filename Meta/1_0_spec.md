# Buildasaur 1.0 Spec

Buildasaur 1.0 will be the first version of Buildasaur using two publicly supported APIs. Previously, Xcode Server's API was only reverse engineered and used, thus not warranting a 1.0 status, because it could change at any moment. Not the case any more with Xcode 7.

Buildasaur 1.0 also need a big visual overhaul, making the onboarding of new projects much easier, straightforward, less likely to configure something incorrectly. It also needs to support multiple projects syncing at the same time, which is roughly supported in code, but no UI was built to be able to add multiple projects yet. Last but not least, Buildasaur 1.0 should give user a nice overview of all their projects syncing at the moment with statuses and glanceable information points.

On the other end of the spectrum, we aim to also provide a pure command line interface (CLI) for Buildasaur, so that it can be ran only from the command line. In that case, the configuration folder would be passed in and Buildasaur would start syncing right away, running only as a process with no GUI. 

Overall, we hope to make Buildasaur 1.0 a very simple, but even more powerful tool, that could let anyone using Xcode Server take a full advantage of its integration with GitHub (and potentially other services).

## Onboarding Requirements

This is a flow of creating a new synced project in Buildasaur. Each project has a 1) Xcode Server Configuration, allowing it to talk to its Xcode Server (these might be shared between multiple projects, but they don't have to be), 2) GitHub and git credentials (these might as well be shared), 3) Xcode project path and Build Template, which is unique to each project, 4) Syncer parameters, which are unique to each project.

Sections will be described in the order in which we need the user to fill them in, validating after each step that the information is valid (like a pkg installation flow on OS X, e.g.), otherwise not letting them continue. Each subsequent section depends on the previous one being valid.

### Xcode Server Credentials
- **host** - an url string
- **username** - string
- **password** - secure string
- (MAYBE: create a dummy blueprint and get the server fingerprint to the user, so they can validate?)
- validation: goes to Xcode server and validates that this user can create Bots. 

### GitHub & Git Credentials
- **GitHub Personal API token** - get one at https://github.com/settings/tokens (when signed in) - send user there with a button
- **SSH keys** - show sheet for user to select where their keys are - shortcut for ~/.ssh/id_rsa.pub (and no-.pub next to it). (MAYBE: let them create new SSH keys right there)
- **SSH passphrase** - optional SSH passphrase
- validation: 1) go to GitHub and validate token that we have read/write rights, 2) create blueprint with these git credentials and ask for branches

### Xcode Project/Workspace Path
- **project/workspace path OR GitHub URL** - popup a sheet letting the user choose their Xcode project/workspace, from which we pull information and which is the project tested (MAYBE: just allow them to search for their project on GitHub **only iff** we find out a way to check out the repo in a temp location instead, would be nicer)

### Build Template
- configure how each bot should be configured. User can have existing Build Templates for this project, but can also create new ones. What needs to be filled in a Build Template follows:

- **scheme**
- ...

**THIS DOCUMENT IS STILL WIP**

