defmodule Genex.Credentials do
  @moduledoc """
  Defines a struct that holds the account, username and password and
  some helper methods for dealing with the data
  """

  alias __MODULE__

  @type t :: %Credentials{account: String.t(), username: String.t(), password: String.t()}

  @derive Jason.Encoder
  defstruct [:account, :username, :password]

  def new(%{"account" => account, "username" => username, "password" => password}) do
    %Credentials{account: account, username: username, password: password}
  end

  def new(account, username, password) do
    %Credentials{account: account, username: username, password: password}
  end
end
