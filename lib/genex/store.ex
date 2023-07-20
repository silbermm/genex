defmodule Genex.Store do
  @moduledoc """
  An implementation of the `Genex.StoreAPI` for `:mnesia`.
  """

  alias Genex.Store.MnesiaResults
  alias Genex.Passwords.Entity
  require Logger

  @tables [
    {TableIds, [:table_name, :last_id], []},
    {Passwords, [:id, :key, :hash, :profile, :data], [:key, :hash, :profile]}
  ]

  @counters [Passwords]

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

  def init_tables() do
    :mnesia.set_master_nodes([node()])

    %MnesiaResults{}
    |> create_tables()
    |> create_counters()
    |> check_errors()
  end

  @doc """
  Retrieve all the passwords in Mnesia
  """
  @spec all_passwords() :: [Entity.t()]
  def all_passwords() do
    fun = fn ->
      :mnesia.select(Passwords, [
        {
          {Passwords, :"$1", :"$2", :"$3", :"$4", :"$5"},
          [{:>, :"$1", 0}],
          [:"$$"]
        }
      ])
    end

    case :mnesia.transaction(fun) do
      {:atomic, res_list} ->
        {:ok, Enum.map(res_list, &Entity.new/1)}

      {:aborted, err} ->
        {:error, err}
    end
  end

  @doc """
  Save a secret in Mnesia
  """
  @spec save(Entity.t()) :: {:ok, Entity.t()} | {:error, :binary}
  def save(entity) do
    # create a new id
    index = :mnesia.dirty_update_counter(TableIds, Passwords, 1)

    fun = fn ->
      :mnesia.write({Passwords, index, entity.key, entity.hash, entity.profile, entity})
    end

    case :mnesia.transaction(fun) do
      {:atomic, res} ->
        {:ok, %{entity | id: index}}

      {:aborted, err} ->
        {:error, err}
    end
  end

  @doc """
  Find passwords based on a specific column in the DB
  """
  def find_passwords_by(key, search) do
    key
    |> build_password_search_function(search)
    |> :mnesia.transaction()
    |> case do
      {:atomic, res_list} -> {:ok, Enum.map(res_list, &Entity.new/1)}
      {:aborted, err} -> {:error, err}
    end
  end

  defp build_password_search_function(:id, search_string),
    do: fn -> :mnesia.match_object({Passwords, search_string, :_, :_, :_, :_}) end

  defp build_password_search_function(:key, search_string),
    do: fn -> :mnesia.match_object({Passwords, :_, search_string, :_, :_, :_}) end

  defp build_password_search_function(:profile, search_string),
    do: fn -> :mnesia.match_object({Passwords, :_, :_, :_, search_string, :_}) end

  defp check_errors(%{errors: errors}) when length(errors) > 0, do: {:error, errors}

  defp check_errors(_) do
    for {table, _, _} <- @tables do
      table |> :mnesia.force_load_table() |> IO.inspect(label: "FORCE LOAD")
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

    :mnesia.wait_for_tables([Passwords, TableIds], 10_000)

    find_fun = fn ->
      :mnesia.read({TableIds, table})
    end

    case :mnesia.transaction(find_fun) do
      {:atomic, [{_, _, _}]} ->
        Logger.debug("Counter already exists")
        {:ok, :counter, table}

      _ ->
        Logger.debug("Counter does not already exist")

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
end
