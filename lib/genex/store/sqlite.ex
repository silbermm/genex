defmodule Genex.Store.Sqlite do
  @moduledoc """
  Implememnts the store behaviour with SQLite 
  as the storage engine.
  """
  @behaviour Genex.StoreAPI

  require Logger

  @db_dir Application.compile_env!(:genex, :homedir)

  @impl true
  def init() do
    Logger.debug("Initialising DB")
    case Exqlite.Connection.connect(database: Path.join(@db_dir, "db")) do
      {:ok, conn} -> {:ok, conn}
      err -> err
    end
  end

  @impl true
  def init_tables() do
    :ok
  end

  @impl true
  def save_password(_psd) do
    :ok
  end

  @impl true
  def find_password_by(_arg0, _binary) do
    :ok
  end

  @impl true
  def all_passwords() do
    []
  end
end
