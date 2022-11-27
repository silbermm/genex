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
          timestamp: DateTime.t(),
          deleted_on: DateTime.t()
        }

  @derive Jason.Encoder
  defstruct [
    :id,
    :encrypted_passphrase,
    :passphrase,
    :account,
    :username,
    :timestamp,
    :comment,
    :deleted_on
  ]

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

  def new(
        {Passwords, id, account, username, encrypted_passphrase, created_at, deleted_on, _comment}
      ) do
    %Password{
      id: id,
      account: account,
      username: username,
      encrypted_passphrase: encrypted_passphrase,
      passphrase: "********",
      timestamp: created_at,
      deleted_on: deleted_on
    }
  end

  def new([id, account, username, encrypted_passphrase, created_at, deleted_on, _comment]) do
    %Password{
      id: id,
      account: account,
      username: username,
      encrypted_passphrase: encrypted_passphrase,
      passphrase: "********",
      timestamp: created_at,
      deleted_on: deleted_on
    }
  end

  # Build a password from a call to remote
  def new(%{
        "account" => account,
        "comment" => comment,
        "encrypted_passphrase" => passphrase,
        "timestamp" => timestamp,
        "username" => username,
        "deleted_on" => deleted_on
      }) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, datetime, _} ->
        %Password{
          account: account,
          username: username,
          comment: comment,
          encrypted_passphrase: passphrase,
          passphrase: "********",
          timestamp: datetime,
          deleted_on: maybe_build_datetime(deleted_on)
        }

      {:error, _reason} ->
        # if the timestamp is off, we can't reliably save the password
        nil
    end
  end

  defp maybe_build_datetime(nil), do: nil

  defp maybe_build_datetime(%DateTime{} = timestamp), do: timestamp

  defp maybe_build_datetime(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
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

  @doc "Add a deleted_on timestamp of right now"
  @spec add_deleted_on(Password.t()) :: Password.t()
  def add_deleted_on(%Password{} = password) do
    %{password | deleted_on: DateTime.now!("Etc/UTC")}
  end

  @doc "Remove the encrypted password from the password struct"
  @spec remove_encrypted_passphrase(Password.t()) :: Password.t()
  def remove_encrypted_passphrase(%Password{} = password) do
    %{password | encrypted_passphrase: ""}
  end

  @doc """
  Merge the remote_password with the local password

  Currently puts the id of the local password on the remote password
  """
  @spec merge(Password.t(), Password.t()) :: Password.t()
  def merge(%Password{} = main_password, %Password{} = data_password) do
    %{data_password | id: main_password.id}
  end
end
