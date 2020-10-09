# Genex

Build a password from readable words using the [Diceware](http://world.std.com/~reinhold/diceware.html) word list.

## Installation

`mix escript.install github silbermm/genex`

This will install genex into your ~/.mix/escripts directory.

> You should add ~/.mix/escripts to your PATH

If you installed elixir with [asdf](https://github.com/asdf-vm/asdf), make sure to run `asdf reshim elixir`

## Setup

Create a new rsa public/private keypair (requires openssl is installed on your system)

```
genex --create-certs
```

This creates two  files in a new folder in your home directory named `.genex/` (notice the `.` in the folder name). genex will use these files to encrypt and decrypt your passwords.

> Don't lose the private key, in fact, back it up somewhere safe. If you lose the file, there will be no way to recover your passwords!

## Usage

`genex --generate` will display a generated password on the screen. Continue to run it until you get one you can remember.

Once you agree that you want to save the password, it will add it to a file stored by default at `~/.genex/passwords`. The file will be JSON formatted and have you encrypted username and password in it. 

You can view your previously saved passwords using `genex --find account_name` where `acccount_name` is the account you saved your password under.
