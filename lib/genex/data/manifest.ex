defmodule Genex.Data.Manifest do
  @moduledoc "The struct that holds the manifest data"

  alias __MODULE__

  @type t() :: %__MODULE__{
          id: String.t(),
          host: String.t(),
          os: atom(),
          error: :invalid | nil,
          is_local: bool(),
          remote: nil | Genex.Remote.RemoteSystem.t()
        }
  defstruct [:id, :host, :error, :os, :is_local, :remote]

  def new({id, host, os, is_local}),
    do: %Manifest{id: id, host: host, os: os, is_local: is_local}

  def new({id, host, os, is_local, remote}),
    do: %Manifest{id: id, host: host, os: os, is_local: is_local, remote: remote}

  def new(%{id: id, host: host, os: os}),
    do: %Manifest{id: id, host: host, os: os, is_local: false}

  def new(_), do: %Manifest{error: :invalid}

  def add_remote(%Manifest{} = manifest, %Genex.Remote.RemoteSystem{} = remote) do
    %Manifest{manifest | remote: remote}
  end
end
