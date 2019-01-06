defmodule Genex.Credentials do
  @moduledoc """
  Defines a struct that holds the account, username and password and 
  some helper methods for dealing with the data
  """

  alias __MODULE__

  defstruct [:account, :username, :password]

  def new(account, username, password) do
    %Credentials{account: account, username: username, password: password}
  end

end
