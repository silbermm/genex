defmodule Genex.EncryptionAPI do
  @moduledoc """
  An api that defines the behaviour for encrypting and decrypting 
  data in Genex
  """

  @type email :: String.t()

  @doc "Encrypt a diceware password"
  @callback encrypt(email(), Diceware.Passphrase.t()) :: {:ok, binary()} | {:error, binary()}

  @doc "Decrypt a diceware password"
  @callback decrypt(binary()) :: {:ok, Diceware.Passphrase.t()} | {:error, binary()}
end
