defmodule Genex.Store.Mnesia do
  @moduledoc """
  An implementation of the `Genex.StoreAPI` for `:mnesia`.
  """

  @behaviour Genex.StoreAPI
  alias Genex.Store.MnesiaResults
  require Logger

  @tables [
    {TableIds, [:table_name, :last_id]},
    {Passwords, [:id, :account, :username, :encrytped_password, :created_at, :updated_at]}
  ]

  @indexes [
    {Passwords, :account},
    {Passwords, :username}
  ]

  @counters [Passwords]

  @impl true
  def init() do
    Logger.debug("Initialising DB")
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
    %MnesiaResults{}
    |> create_tables()
    |> create_indexes()
    |> create_counters()
    |> check_errors()
  end

  @impl true
  def save_password(password) do
    Logger.debug("Saving password")

    index = :mnesia.dirty_update_counter(TableIds, Passwords, 1)

    fun = fn ->
      :mnesia.write(
        {Passwords, index, password.account, password.username, password.encrypted_passphrase,
         password.timestamp, password.timestamp}
      )
    end

    :mnesia.transaction(fun)
  end

  defp check_errors(%{errors: errors}) when length(errors) > 0, do: {:error, errors}
  defp check_errors(_), do: :ok

  defp create_tables(mnesia_results) do
    Logger.debug("Creating and verifying tables")

    for {table, attributes} <- @tables, reduce: mnesia_results do
      acc ->
        case create_table(table, attributes: attributes) do
          {:ok, table} -> MnesiaResults.add_success(acc, table)
          {:error, table, reason} -> MnesiaResults.add_error(acc, {table, reason})
        end
    end
  end

  defp create_table(table, attributes) do
    Logger.debug("Creating table: #{table}")

    case :mnesia.create_table(table, attributes) do
      {:atomic, :ok} ->
        {:ok, table}

      {:aborted, {:already_exists, _}} ->
        {:ok, table}

      {:aborted, reason} ->
        Logger.error("failed because: (#{inspect(reason)})")
        {:error, table, reason}
    end
  end

  defp create_indexes(%MnesiaResults{errors: errors} = results) when length(errors) > 0,
    do: results

  defp create_indexes(mnesia_results) do
    Logger.debug("Creating and verifying indexes")

    for {table, column} <- @indexes, reduce: mnesia_results do
      acc ->
        case create_index(table, column) do
          {:ok, table, column} -> MnesiaResults.add_success(acc, {table, column})
          {:error, table, column, reason} -> MnesiaResults.add_error(acc, {table, column, reason})
        end
    end
  end

  @spec create_index(module(), atom()) ::
          {:ok, module(), atom()} | {:error, module(), atom(), any()}
  defp create_index(table, column) do
    Logger.debug("Creating index for #{column} on #{table}")

    case :mnesia.add_table_index(table, column) do
      {:atomic, :ok} ->
        {:ok, table, column}

      {:aborted, {:already_exists, _, _}} ->
        {:ok, table, column}

      {:aborted, reason} ->
        Logger.error(
          "Failed creating index on #{column} of table #{table} because: (#{inspect(reason)})"
        )

        {:error, table, column, reason}
    end
  end

  defp create_counters(mnesia_results) do
    Logger.debug("Creating counters")
    for table <- @counters, reduce: mnesia_results do
      acc ->
        case create_counter(table) do
          {:ok, :counter, table} ->
            MnesiaResults.add_success(acc, {table, :counter})

          {:error, :counter, table, reason} ->
            MnesiaResults.add_error(acc, {table, :counter, reason})
        end
    end
  end

  defp create_counter(table) do
    Logger.debug("Creating counter for #{table}")

    fun = fn ->
      :mnesia.write({TableIds, table, 100})
    end

    case :mnesia.transaction(fun) do
      {:atomic, :ok} ->
        {:ok, :counter, table}

      {:aborted, reason} ->
        Logger.error("Failed creating counter for #{table} because: (#{inspect(reason)})")

        {:error, :counter, table, reason}
    end
  end
end
