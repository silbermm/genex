defmodule Genex.StoreAPI do
  @moduledoc """
    The store API
  """

  @callback init() :: :ok | {:error, binary()}
  @callback init_tables() :: :ok | {:error, binary()}
end
