# Genex

A simple and secure password management system using a local-first mentality

## Goals
* Provide a simple, intuitive interface to generate secure readable passwords on a users computer
* Securely save passwords on the users computer
* Securely share the passwords with others using PGP/GPG

## How it works
TODO


## Installation

1. Grab the latest release for your system from the [release](https://github.com/silbermm/genex/releases) page. 
2. Extract the file
3. Add (symlink) the genex.sh file to your path.

## Setup

You'll also need [gpg]() installed on your system, available in the `PATH`, and a PGP key configured.
> There a plenty of guides for GPG out there if you need help here.
> [Here is a good one](https://gock.net/blog/2020/gpg-cheat-sheet/) 


## Usage
To begin using `genex`, you'll need to start by configuring it, run:
```bash
$ genex config --guided
```

> #### TIP
> all commands allow for the `--profile <profile_name>` option which is helpful if you want to separate passwords for work/home/school etc.

If you decided to setup syncing, you'll need to login to your server.
```bash
$ genex login
```

Finally, you're ready to use the tool.
```bash
$ genex
```

## Sharing passwords
TODO
