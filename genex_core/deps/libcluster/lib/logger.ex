defmodule Cluster.Logger do
  @moduledoc false
  require Logger

  def debug(t, msg) do
    case Application.get_env(:libcluster, :debug, false) do
      dbg when dbg in [nil, false, "false"] ->
        :ok

      _ ->
        log(:debug, t, msg)
    end
  end

  def info(t, msg), do: log(:info, t, msg)
  def warn(t, msg), do: log(:warn, t, msg)
  def error(t, msg), do: log(:error, t, msg)

  defp log(level, t, msg), do: Logger.log(level, "[libcluster:#{t}] #{msg}")
end
