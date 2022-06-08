defmodule Genex.Passwords.Password do
  @moduledoc """
  Defines a Password
  """

  alias __MODULE__

  @type t :: %Password{
          account: binary(),
          username: binary(),
          comment: binary() | nil,
          encrypted_passphrase: String.t() | nil,
          timestamp: DateTime.t()
        }

  @derive Jason.Encoder
  defstruct [:encrypted_passphrase, :account, :username, :timestamp, :comment]

  @doc """
  Create a new password
  """
  @spec new(binary(), binary()) :: t()
  def new(account, username),
    do: %Password{
      account: account,
      username: username,
      timestamp: DateTime.now!("Etc/UTC")
    }

  @doc """
  Add an encrypted passphrase to a password
  """
  @spec add_passphrase(t(), binary()) :: t()
  def add_passphrase(%Password{} = password, encrypted_passphrase),
    do: %{password | encrypted_passphrase: encrypted_passphrase}
end
