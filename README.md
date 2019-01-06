# Genex

Build a password from readable words using the [Diceware](http://world.std.com/~reinhold/diceware.html) word list.

## Installation

`mix escript.install github silbermm/genex`

This will install genex into your ~/.mix/escripts directory.

> You should add ~/.mix/escripts to your PATH

If you installed elixir with [asdf](https://github.com/asdf-vm/asdf), make sure to run `asdf reshim elixir`

## Setup

Create a new rsa public/private keypair

```
openssl genrsa -out genex_private.pem 2048
openssl rsa -in genex_private.pem -out genex_public.pem -outform PEM -pubout
```

Place both files in a new folder in your home directory named `.genex/` (notice the `.` in the folder name). genex will use these files to encrypt and decrypt your password file.


## Usage

`genex` will display a generated password on the screen. Continue to run it until you get one you can remember.

