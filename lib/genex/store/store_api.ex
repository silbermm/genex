defmodule Genex.StoreAPI do
  @moduledoc """
  The store API
  """

  @callback init() :: :ok | {:error, binary()}
  @callback init_tables() :: :ok | {:error, binary()} | {:error, [any()]}

  @callback save_password(Genex.Passwords.Password.t()) :: :ok | {:error, binary()}
  @callback all_passwords() :: {:ok, [Genex.Passwords.Password.t()]} | {:error, binary()}
  @callback find_password_by(:account | :username, binary()) ::
              {:ok, [Genex.Passwords.Password.t()]} | {:error, binary()}
end
