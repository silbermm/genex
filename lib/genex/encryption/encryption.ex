defmodule Genex.Encryption do
  @moduledoc """
    Defines how to load and encrypted file and save plain text to encrypted file
  """

  alias Genex.Data.Credentials

  @callback encrypt(String.t()) :: term
  @callback decrypt(String.t(), String.t() | nil) :: term
  @callback decrypt_credentials(Credentials.t(), String.t()) :: Credentials.t()
end
