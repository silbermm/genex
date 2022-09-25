
# Genex

Build a password from readable words using the [Diceware](http://world.std.com/~reinhold/diceware.html) word list.

## Goals
* Provide a simple, intuitive interface to generate secure readable passwords on a users computer
* Securely save passwords on the users system
* Securly share the passwords using GPG
* Use as few dependencies as possible

## Installation

Grab the latest release for your system from the [release](https://github.com/silbermm/genex/releases) page. Add (symlink) the genex.sh file to your path.

## Setup

You'll also need a gpg installed on your system and available in the `PATH` and a key configured.

Create a configuration file at `~/.genex/config.toml` and add the following content:
```toml
[gpg]
  email = "valid_gpg_email@gpg.org"

[password]
  length = 12
```

where the email is them email attached to your GPG key.``
genex certs

## Usage

* `genex` will display a TUI show allows you to start managing your passwords


## Sharing passwords

TODO

