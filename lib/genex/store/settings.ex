defmodule Genex.Store.Settings do
  @moduledoc false

  @behaviour Genex.Store.TableAPI

  alias __MODULE__

  @type t :: %Settings{
          id: number() | nil,
          profile: binary() | nil,
          gpg_email: binary() | nil,
          password_length: number() | nil,
          timestamp: DateTime.t(),
          action: :insert | :delete
        }

  defstruct [:id, :profile, :gpg_email, :password_length, :timestamp, :action]
  defmodule Error, do: defexception(message: "invalid")

  @default_password_length 6

  @table_name :settings

  ###################
  # STRUCT BEHAVIOR #
  ###################
  @doc "Create a new Settings struct"
  @spec new(binary()) :: t()
  def new(profile) when is_binary(profile),
    do: %Settings{
      profile: profile,
      action: :insert,
      timestamp: DateTime.utc_now(),
      password_length: @default_password_length
    }

  def set_gpg(%Settings{} = settings, gpg_email), do: %{settings | gpg_email: gpg_email}

  def set_password_length(%Settings{} = settings, length),
    do: %{settings | password_length: length}

  @doc "Sets the action for the Settings"
  def set_action(settings, :insert), do: %{settings | action: :insert}
  def set_action(settings, :delete), do: %{settings | action: :delete}

  def set_action(_settings, action),
    do: raise(Error, message: "Invalid action \"#{action}\" for settings")

  def set_id(settings, id), do: %{settings | id: id}

  def is_valid?(%Settings{} = settings),
    do: settings.profile && settings.gpg_email && settings.password_length && settings.id

  def is_valid?(_), do: false

  ####################
  # STORAGE BEHAVIOR #
  ####################
  @impl true
  @spec list() :: [Settings.t()]
  def list() do
    fun = fn ->
      :mnesia.select(@table_name, [
        {
          {@table_name, :"$1", :"$2", :"$3"},
          [{:>, :"$1", 0}],
          [:"$$"]
        }
      ])
    end

    case :mnesia.transaction(fun) do
      {:atomic, res_list} ->
        Enum.map(res_list, fn [_, _, data] -> data end)

      {:aborted, _err} ->
        []
    end
  end

  @impl true
  @spec create(Settings.t()) :: {:ok, Settings.t()} | {:error, :binary}
  def create(settings) do
    # create a new id
    index = :mnesia.dirty_update_counter(:table_ids, @table_name, 1)
    settings = set_id(settings, index)

    fun = fn ->
      :mnesia.write({@table_name, index, settings.profile, settings})
    end

    case :mnesia.transaction(fun) do
      {:atomic, _res} ->
        {:ok, settings}

      {:aborted, err} ->
        {:error, err}
    end
  end

  @impl true
  def find_by(key, search) when key in [:id, :profile] do
    key
    |> build_search_function(search)
    |> :mnesia.transaction()
    |> case do
      {:atomic, res_list} ->
        Enum.map(res_list, fn {_, _id, _, data} -> data end)

      {:aborted, _err} ->
        []
    end
  end

  defp build_search_function(:id, search_string),
    do: fn -> :mnesia.match_object({@table_name, search_string, :_, :_}) end

  defp build_search_function(:profile, search_string),
    do: fn -> :mnesia.match_object({@table_name, :_, search_string, :_}) end
end
