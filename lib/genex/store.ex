defmodule Genex.Store do
  @moduledoc """
  The datastore
  """

  alias Genex.Store.MnesiaResults
  alias Genex.Store.TableAPI
  require Logger

  @tables [
    {:table_ids, [:table_name, :last_id], []},
    {:secrets, [:id, :key, :hash, :profile, :data], [:key, :hash, :profile]},
    {:settings, [:id, :profile, :data], [:profile]}
  ]

  @counters [:secrets, :settings]

  #############
  # Table API #
  #############
  def for(table), do: TableAPI.impl(table)

  ####################
  # Table Management #
  ####################

  @doc """
  Initializes the Mnesia DB
  """
  def init() do
    Logger.debug("Initializing DB")
    current_node = Node.self()

    case :mnesia.system_info(:extra_db_nodes) do
      [] ->
        case :mnesia.create_schema([current_node]) do
          :ok ->
            :mnesia.start()

          {:error, {_, {:already_exists, _}}} ->
            Logger.debug("Already exists")
            :mnesia.start()

          {:error, reason} ->
            Logger.error("Unable to start mnesia: #{inspect(reason)}")
            {:error, reason}
        end

      [_ | _] ->
        :mnesia.start()
    end
  end

  @doc """
  Creates the tables and counters
  """
  def init_tables() do
    :mnesia.set_master_nodes([node()])

    %MnesiaResults{}
    |> create_tables()
    |> create_counters()
    |> check_errors()
  end

  defp check_errors(%{errors: errors}) when length(errors) > 0, do: {:error, errors}

  defp check_errors(_) do
    for {table, _, _} <- @tables do
      :mnesia.force_load_table(table)
    end

    :ok
  end

  defp create_tables(mnesia_results) do
    Logger.debug("Creating and verifying tables")

    for {table, attributes, indexes} <- @tables, reduce: mnesia_results do
      acc ->
        case create_table(table,
               attributes: attributes,
               disc_copies: [Node.self()],
               index: indexes,
               local_content: true
             ) do
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
        Logger.debug("#{table} already exists")
        {:ok, table}

      {:aborted, reason} ->
        Logger.error("failed because: (#{inspect(reason)})")
        {:error, table, reason}
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

    :mnesia.wait_for_tables([:secrets, :table_ids], 10_000)

    find_fun = fn ->
      :mnesia.read({:table_ids, table})
    end

    case :mnesia.transaction(find_fun) do
      {:atomic, [{_, _, _}]} ->
        Logger.debug("Counter already exists")
        {:ok, :counter, table}

      _ ->
        Logger.debug("Counter does not already exist")

        fun = fn ->
          :mnesia.write({:table_ids, table, 100})
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
end
