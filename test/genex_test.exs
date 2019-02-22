defmodule GenexTest do
  use ExUnit.Case
  doctest Genex

  setup do
    creds = Genex.Credentials.new("facebook", "me", "passw0rd")
    [credentials: creds]
  end

  test "saves credentials", context do
    assert Genex.save_credentials(context[:credentials], :correct) === :ok
  end

  test "unable to save already existing account/username" do
    creds = Genex.Credentials.new("gmail", "user", "passw0rd")
    assert Genex.save_credentials(creds, :correct) === {:error, :not_unique}
  end

  test "creates file if not exists already", %{credentials: creds} do
    assert Genex.save_credentials(creds, :noexists) === :ok
  end
end
