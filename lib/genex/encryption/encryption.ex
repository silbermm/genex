defmodule Genex.Encryption do
  @moduledoc """
    Defines how to load and encrypted file and save plain text to encrypted file
  """

  alias Genex.Data.Credentials

  @callback encrypt(String.t()) :: term
  @callback decrypt(String.t(), String.t() | nil) :: term
end
