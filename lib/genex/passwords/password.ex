defmodule Genex.Passwords.Password do
  @moduledoc """
  Defines a Password
  """

  alias __MODULE__

  @type t :: %Password{
          id: integer() | nil,
          account: binary(),
          username: binary(),
          comment: binary() | nil,
          encrypted_passphrase: String.t() | nil,
          passphrase: String.t(),
          timestamp: DateTime.t()
        }

  @derive Jason.Encoder
  defstruct [:id, :encrypted_passphrase, :passphrase, :account, :username, :timestamp, :comment]

  @doc """
  Create a new password
  """
  @spec new(binary(), binary()) :: t()
  def new(account, username),
    do: %Password{
      account: account,
      username: username,
      passphrase: "********",
      timestamp: DateTime.now!("Etc/UTC")
    }

  def new({Passwords, id, account, username, encrypted_passphrase, created_at, _updated_at}) do
    %Password{
      id: id,
      account: account,
      username: username,
      encrypted_passphrase: encrypted_passphrase,
      passphrase: "********",
      timestamp: created_at
    }
  end

  def new([id, account, username, encrypted_passphrase, created_at, _updated_at]) do
    %Password{
      id: id,
      account: account,
      username: username,
      encrypted_passphrase: encrypted_passphrase,
      passphrase: "********",
      timestamp: created_at
    }
  end

  @doc """
  Add an encrypted passphrase to a password
  """
  @spec add_passphrase(t(), binary()) :: t()
  def add_passphrase(%Password{} = password, encrypted_passphrase),
    do: %{password | encrypted_passphrase: encrypted_passphrase}

  @doc """
  Add a unencrypted passphrase to a password
  """
  @spec add_unencrypted_passphrase(t(), String.t()) :: t()
  def add_unencrypted_passphrase(%Password{} = password, passphrase),
    do: %{password | passphrase: passphrase}

end
