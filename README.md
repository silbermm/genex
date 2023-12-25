# Genex

A simple and secure password management system using a local-first mentality

## REPO MOVED TO SOURCEHUT
[https://git.sr.ht/~ahappydeath/genex](https://git.sr.ht/~ahappydeath/genex)


## Goals
* Provide a simple, intuitive interface to generate secure readable passwords on a users computer
* Securely save passwords on the users computer using PGP encryption
* Securely share the passwords with others using PGP/GPG

## Todo
* [ ] Allow editing of an existing passphrase
* [ ] Show history of a passphrase
* [ ] Allow secure sharing of passphrases
* [ ] 'eject' (export?) passphrases for importing into a different tool

## How it works
Generating a key uses the Diceware method of using multiple random dictionary words together to form a passphrase.

Once the passphrase is generated and you decide to save it and pick a key/tag/label to save it under, it is encrypted using PGP and then stored on disk, Genex never stores your password in plain text on disk.

The key/tag/label that you choose to store the passphrase under can be anything string you like, but must be unique. If you save a new passphrase under an existing key, the old passphrase will be overwritten. 

The key is typically used to identify the account/username that the passphrase is used to access, for instance, I might store my github password under the key `github.com/silbermm`. There is as much flexibility as you want.

## Installation
### Build from Source
TODO

### Install pre-built binary
TODO

## Setup

You'll also need [gpg]() installed on your system, available in the `PATH`.
> There a plenty of guides for GPG out there if you need help here.
> [Here is a good one](https://gock.net/blog/2020/gpg-cheat-sheet/) 

## Usage
To begin using `genex`, you'll need to start by configuring it, run:
```bash
$ genex config --guided
```

> #### TIP
> all commands allow for the `--profile <profile_name>` option which is helpful if you want to separate passwords for work/home/school etc.

Finally, you're ready to start generating passwords
```bash
$ genex generate
```

You can list the keys you have currently used for storing passwords:
```bash
$ genex ls
```

and then get the actually passphrase from the key
```bash
$ genex get <key>
```

## Sharing passwords
TODO
