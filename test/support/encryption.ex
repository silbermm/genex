defmodule Genex.Support.Encryption do
  @moduledoc """
  Encryption and Decryption for tests
  """

  @impl Encryption
  def load(:correct) do
    {:ok, """
      [
        { "account": "gmail", "username": "user", "password": "pass" },
        { "account": "twitter", "username": "tweeter", "password": "tw33t" }
      ]
    """}
  end
  def load(:incorrect), do: {:error, :nokeydecrypt}
  def load(:badkey), do: {:error, :noloadkey}
  def load(:noexists), do: {:error, :noexists}


  @impl Encryption
  def save(:error), do: {:error, "Unable to save to encrypted file"}
  def save(data), do: :ok

end
