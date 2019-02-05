defmodule Genex.Encryption do
  @moduledoc """
    Defines how to load and encrypted file and save plain text to encrypted file
  """
  @callback load :: {:ok, term} | {:error, String.t()}
  @callback save(String.t()) :: term
  @callback generate_keys(String.t()) :: Boolean
end
