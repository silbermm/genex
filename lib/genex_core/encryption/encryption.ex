defmodule Genex.Core.Encryption do
  @moduledoc """
    Defines how to load and encrypted file and save plain text to encrypted file
  """

  @callback encrypt(String.t()) :: term
  @callback decrypt(String.t(), String.t() | nil) :: term
end
