defmodule Genex.MnesiaStore do
  @behaviour Genex.StoreAPI

  @impl true
  def init() do
    current_node = Node.self()

    case :mnesia.system_info(:extra_db_nodes) do
      [] ->
        case :mnesia.create_schema([current_node]) do
          :ok -> :mnesia.start()
          {:error, {_, {:already_exists, _}}} -> :mnesia.start()
          {:error, reason} -> {:error, reason}
        end

      [_ | _] ->
        :mnesia.start()
    end
  end

  @impl true
  def init_tables() do
    case :mnesia.create_table(
           Passwords,
           attributes: [:id, :account, :username, :encrytped_password, :created_at, :updated_at]
         ) do
      {:atomic, :ok} ->
        :ok

      {:aborted, {:already_exists, _}} ->
        :ok

      other ->
        IO.inspect(other)
        other
    end
  end
end
