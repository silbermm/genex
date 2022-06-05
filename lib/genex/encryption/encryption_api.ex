defmodule Genex.EncryptionAPI do
  @moduledoc """
  An api that defines the behaviour for encrypting and decrypting 
  data in Genex
  """

  @type email :: String.t()

  @doc "Encrypt a diceware password"
  @callback encrypt(email(), Diceware.t()) :: {:ok, binary()} | {:error, binary()}

  @doc "Decrypt a diceware password"
  @callback decrypt(binary()) :: {:ok, Dicware.t()} | {:error, binary()}
end
