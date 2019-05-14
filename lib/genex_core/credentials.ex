defmodule Genex.Core.Credentials do
  @moduledoc """
  Defines a struct that holds the account, username and password and
  some helper methods for dealing with the data
  """

  alias __MODULE__

  @type t :: %Credentials{account: String.t(), username: String.t(), password: String.t(), encrypted_password: String.t()}

  @derive {Jason.Encoder, only: [:account, :username, :encrypted_password]}
  defstruct [:account, :username, :password, :encrypted_password]

  def new(%{"account" => account, "username" => username, "password" => password}) do
    %Credentials{account: account, username: username, password: password}
  end

  def new(account, username, password) do
    %Credentials{account: account, username: username, password: password}
  end

  def add_encrypted_password(%Credentials{account: account, username: username, password: password}, encrypted_password) do
    %Credentials{account: account, username: username, password: password, encrypted_password: encrypted_password}
  end
end
