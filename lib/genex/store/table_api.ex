defmodule Genex.Store.TableAPI do
  @moduledoc """

  """
  @callback list() :: list(struct())
  @callback create(struct()) :: {:ok, struct()} | {:error, any()}
  @callback find_by(atom(), String.t() | number()) :: list(struct())

  def impl(table) do
    case table do
      :secrets -> Genex.Store.Secret
      :settings -> Genex.Store.Settings
      table -> raise "Invalid table specified: #{table}"
    end
  end

  def create(impl, data), do: impl.create(data)
  def list(impl), do: impl.list()
  def find_by(impl, key, filter), do: impl.find_by(key, filter)
end
