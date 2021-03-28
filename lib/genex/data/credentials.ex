defmodule Genex.Data.Credentials do
  @moduledoc """
  Defines a struct that holds the account, username and password and
  some helper methods for dealing with the data
  """

  alias __MODULE__

  @type t :: %Credentials{
          account: String.t(),
          username: String.t(),
          passphrase: Diceware.Passphrase.t(),
          created_at: DateTime.t()
        }

  @derive {Jason.Encoder, only: [:account, :username, :created_at, :passphrase]}
  defstruct [:account, :username, :passphrase, :created_at]

  def empty() do
    %Credentials{}
  end

  def new(%{
        "account" => account,
        "username" => username,
        "passphrase" => passphrase,
        "created_at" => created_at
      }) do
    %Credentials{
      account: account,
      username: username,
      created_at: created_at,
      passphrase: Diceware.Passphrase.new(passphrase)
    }
  end

  def new(account, username, %Diceware.Passphrase{} = passphrase) do
    %Credentials{
      account: account,
      username: username,
      passphrase: passphrase,
      created_at: DateTime.utc_now()
    }
  end
end
