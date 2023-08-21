defmodule Genex.Store.Secret do
  @behaviour Genex.Store.TableAPI

  alias __MODULE__
  require Logger

  @type t :: %Secret{
          id: number() | nil,
          key: String.t(),
          hash: pos_integer(),
          encrypted_password: binary(),
          timestamp: DateTime.t(),
          action: :insert | :delete | :update | nil,
          profile: String.t()
        }

  defstruct [:id, :key, :hash, :encrypted_password, :timestamp, :action, :profile]
  defmodule Error, do: defexception(message: "invalid")

  @table_name :secrets

  ###################
  # STRUCT BEHAVIOR #
  ###################

  @doc """
  Generate an Secret from data
  """
  def new(key, hash, encrypted_password) do
    %Secret{
      key: key,
      hash: hash,
      encrypted_password: encrypted_password,
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Sets the action for the Secret"
  def set_action(secret, :insert), do: %{secret | action: :insert}
  def set_action(secret, :update), do: %{secret | action: :update}
  def set_action(secret, :delete), do: %{secret | action: :delete}
  def set_action(_secret, action), do: raise(Error, message: "Invalid action #{action}")

  @doc "Sets the profile for the Secret"
  def set_profile(secret, profile \\ "default"), do: %{secret | profile: profile}

  @doc "Sets the id of an secret"
  def set_id(secret, id), do: %{secret | id: id}

  ####################
  # STORAGE BEHAVIOR #
  ####################
  @impl true
  @spec list() :: [Secret.t()]
  def list() do
    fun = fn ->
      :mnesia.select(@table_name, [
        {
          {@table_name, :"$1", :"$2", :"$3", :"$4", :"$5"},
          [{:>, :"$1", 0}],
          [:"$$"]
        }
      ])
    end

    case :mnesia.transaction(fun) do
      {:atomic, res_list} ->
        Enum.map(res_list, fn [_id, _, _, _, data] ->
          data
        end)

      {:aborted, err} ->
        Logger.warning(inspect(err))
        []
    end
  end

  @impl true
  @spec create(Secret.t()) :: {:ok, Secret.t()} | {:error, :binary}
  def create(secret) do
    # create a new id
    index = :mnesia.dirty_update_counter(:table_ids, @table_name, 1)
    secret = set_id(secret, index)

    fun = fn ->
      :mnesia.write({@table_name, index, secret.key, secret.hash, secret.profile, secret})
    end

    case :mnesia.transaction(fun) do
      {:atomic, _res} ->
        {:ok, secret}

      {:aborted, err} ->
        {:error, err}
    end
  end

  @impl true
  def find_by(key, search) do
    key
    |> build_secret_search_function(search)
    |> :mnesia.transaction()
    |> case do
      {:atomic, res_list} ->
        Enum.map(res_list, fn {_, _id, _, _, _, data} -> data end)

      {:aborted, err} ->
        Logger.warning(inspect(err))
        []
    end
  end

  defp build_secret_search_function(:id, search_string),
    do: fn -> :mnesia.match_object({@table_name, search_string, :_, :_, :_, :_}) end

  defp build_secret_search_function(:key, search_string),
    do: fn -> :mnesia.match_object({@table_name, :_, search_string, :_, :_, :_}) end

  defp build_secret_search_function(:profile, search_string),
    do: fn -> :mnesia.match_object({@table_name, :_, :_, :_, search_string, :_}) end
end
