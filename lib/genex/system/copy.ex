defmodule Genex.System.Copy do
  @moduledoc """
  Copy data to the system clipboard
  Requires `xclip` on Linux or pbcopy on Mac
  """

  def copy(""), do: {:error, :nodata}

  def copy(data) do
    xclip = System.find_executable("xclip")
    copy(data, xclip)
  end

  def copy(_data, nil), do: {:error, :nocmd}

  def copy(data, _) do
    port = Port.open({:spawn, "xclip -selection 'clip'"}, [:binary])
    send(port, {self(), {:command, data}})
    send(port, {self(), :close})
    :ok
  end
end
