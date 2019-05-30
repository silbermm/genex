defmodule Genex.Core.PasswordFile do
  @moduledoc """
  Takes care of safely loading and writing the passwords file.
  """

  alias Genex.Core.Environment

  @spec load() :: {:ok, list()} | :error
  def load() do
    with filename <- Environment.load_variable("GENEX_PASSWORDS", :passwords_file),
         {:ok, file} <- File.read(filename) do
      Jason.decode(file)
    else
      _err -> :error
    end
  end

  @spec write(binary()) :: :ok | {:error, atom()}
  def write(data) do
    filename = Environment.load_variable("GENEX_PASSWORDS", :passwords_file)
    File.write(filename, data)
  end
end
