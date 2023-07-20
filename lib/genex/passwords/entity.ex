defmodule Genex.Passwords.Entity do
  ### Secret?
  @moduledoc """
  Defines a password entity
  """
  alias __MODULE__

  @type t :: %Entity{
          id: number() | nil,
          key: String.t(),
          hash: pos_integer(),
          encrypted_password: binary(),
          timestamp: DateTime.t(),
          action: :insert | :delete | nil,
          profile: String.t()
        }

  defstruct [:id, :key, :hash, :encrypted_password, :timestamp, :action, :profile]

  defmodule Error do
    defexception message: "invalid"
  end

  @doc """
  Generate an Entity from data
  """
  def new(key, hash, encrypted_password) do
    %Entity{
      key: key,
      hash: hash,
      encrypted_password: encrypted_password,
      timestamp: DateTime.utc_now()
    }
  end

  def new(mnesia_lst) when is_list(mnesia_lst) do
    [id, _, _, _, data] = mnesia_lst
    %{data | id: id}
  end

  def new(mnesia_tpl) when is_tuple(mnesia_tpl) do
    {_, id, _, _, _, data} = mnesia_tpl
    %{data | id: id}
  end

  @doc "Sets the action for the Entity"
  def set_action(entity, :insert), do: %{entity | action: :insert}
  def set_action(entity, :delete), do: %{entity | action: :delete}
  def set_action(entity, action), do: raise(Error, message: "Invalid action #{action}")

  @doc "Sets the profile for the Entity"
  def set_profile(entity, profile \\ "default"), do: %{entity | profile: profile}
end
