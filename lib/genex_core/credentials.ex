defmodule Genex.Core.Credentials do
  @moduledoc """
  Defines a struct that holds the account, username and password and
  some helper methods for dealing with the data
  """

  alias __MODULE__

  @type t :: %Credentials{
          account: String.t(),
          username: String.t(),
          password: String.t(),
          encrypted_password: String.t() | nil,
          created_at: DateTime.t()
        }

  @derive {Jason.Encoder, only: [:account, :username, :encrypted_password, :created_at]}
  defstruct [:account, :username, :password, :encrypted_password, :created_at]

  def new(%{"account" => account, "username" => username, "password" => password}) do
    %Credentials{
      account: account,
      username: username,
      password: password,
      created_at: DateTime.utc_now()
    }
  end

  def new(%{"account" => account, "username" => username, "encrypted_password" => password}) do
    %Credentials{
      account: account,
      username: username,
      encrypted_password: password,
      created_at: DateTime.utc_now()
    }
  end

  def new(%{
        "account" => account,
        "username" => username,
        "encrypted_password" => password,
        "created_at" => created
      }) do
    %Credentials{
      account: account,
      username: username,
      encrypted_password: password,
      created_at: created
    }
  end

  def new(account, username, password) do
    %Credentials{
      account: account,
      username: username,
      password: password,
      created_at: DateTime.utc_now()
    }
  end

  def add_encrypted_password(%Credentials{} = creds, encrypted_password) do
    %Credentials{creds | encrypted_password: encrypted_password}
  end

  def add_password(%Credentials{} = creds, password) do
    %Credentials{creds | password: password}
  end
end
