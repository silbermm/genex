defmodule Genex.StoreAPI do
  @moduledoc """
  The store API
  """

  @callback init() :: :ok | {:error, binary()}
  @callback init_tables() :: :ok | {:error, binary()} | {:error, [any()]}

  @callback save_password(Genex.Passwords.Password.t()) :: :ok | {:error, binary()} 
end
