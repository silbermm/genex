defmodule Genex.Store.Mnesia do
  @moduledoc """
  An implementation of the `Genex.StoreAPI` for `:mnesia`.
  """

  @behaviour Genex.StoreAPI
  alias Genex.Store.MnesiaResults
  require Logger

  @tables [
    {TableIds, [:table_name, :last_id], []},
    {Passwords, [:id, :account, :username, :encrytped_password, :created_at, :updated_at],
     [:account, :username]}
  ]

  @counters [Passwords]

  @impl true
  def init() do
    Logger.debug("Initialising DB")
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

  @impl true
  def init_tables() do
    %MnesiaResults{}
    |> create_tables()
    |> create_counters()
    |> check_errors()
  end

  @impl true
  def all_passwords() do
    Logger.debug("Get all passwords")

    fun = fn ->
      :mnesia.select(Passwords, [
        {
          {Passwords, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6"},
          [{:>, :"$1", 0}],
          [:"$$"]
        }
      ])
    end

    case :mnesia.transaction(fun) do
      {:atomic, res_list} ->
        {:ok, Enum.map(res_list, &Genex.Passwords.Password.new/1)}

      {:aborted, err} ->
        {:error, err}
    end
  end

  @impl true
  def save_password(password) do
    Logger.debug("Saving password")

    # create a new id
    index = :mnesia.dirty_update_counter(TableIds, Passwords, 1)

    fun = fn ->
      :mnesia.write(
        {Passwords, index, password.account, password.username, password.encrypted_passphrase,
         password.timestamp, password.timestamp}
      )
    end

    case :mnesia.sync_transaction(fun) do
      {:atomic, res} ->
        Logger.debug(inspect(res))
        :ok

      {:aborted, err} ->
        {:error, err}
    end
  end

  @impl true
  def find_password_by(column, search_string) do
    column
    |> build_password_search_function(search_string)
    |> :mnesia.transaction()
    |> case do
      {:atomic, res_list} -> {:ok, Enum.map(res_list, &Genex.Passwords.Password.new/1)}
      {:aborted, err} -> {:error, err}
    end
  end

  defp build_password_search_function(:account, search_string),
    do: fn -> :mnesia.match_object({Passwords, :_, search_string, :_, :_, :_, :_}) end

  defp build_password_search_function(:username, search_string),
    do: fn -> :mnesia.match_object({Passwords, :_, :_, search_string, :_, :_, :_}) end

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
               index: indexes
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
