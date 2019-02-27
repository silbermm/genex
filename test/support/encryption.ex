defmodule Genex.Support.Encryption do
  @moduledoc """
  Encryption and Decryption for tests
  """
  @behaviour Genex.Encryption

  @impl Genex.Encryption
  def load(:correct) do
    {:ok,
     """
       [
         { "account": "gmail", "username": "user", "password": "pass" },
         { "account": "twitter", "username": "tweeter", "password": "tw33t" }
       ]
     """}
  end
  def load(:incorrect), do: {:error, :nokeydecrypt}
  def load(:badkey), do: {:error, :noloadkey}
  def load(:noexists), do: {:error, :noexists}

  @impl Genex.Encryption
  def save(:error), do: {:error, "Unable to save to encrypted file"}
  def save(_data), do: :ok
end
