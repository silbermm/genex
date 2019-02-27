defmodule GenexTest do
  use ExUnit.Case
  doctest Genex

  setup do
    facebook = Genex.Credentials.new("facebook", "me", "passw0rd")
    gmail = Genex.Credentials.new("gmail", "user", "pass")

    [new_creds: facebook, used_creds: gmail]
  end

  test "saves credentials", %{new_creds: facebook} do
    assert Genex.save_credentials(facebook, :correct) === :ok
  end

  test "unable to save already existing account/username", %{used_creds: gmail} do
    assert Genex.save_credentials(gmail, :correct) === {:error, :not_unique}
  end

  test "creates file if not exists already", %{new_creds: facebook} do
    assert Genex.save_credentials(facebook, :noexists) === :ok
  end

  test "finds credentials in existing file", %{used_creds: gmail} do
    assert Genex.find_credentials("gmail", :correct) === [gmail]
  end

  test "find credentials unable to decrypt private key", %{used_creds: gmail} do
    assert Genex.find_credentials("gmail", :incorrect) === {:error, :password}
  end

  test "find credentials, no file exists", %{new_creds: facebook} do
    assert Genex.find_credentials("gmail", :noexists) === :error
  end

  test "generates random password" do
    password = Genex.generate_password
    assert Enum.count(password) == 6
    assert Enum.all?(password, fn p -> String.length(p) > 0 end)
    assert password == Enum.uniq(password)
  end

  test "generates random password - custom number of words" do
    password = Genex.generate_password(8)
    assert Enum.count(password) == 8
    assert Enum.all?(password, fn p -> String.length(p) > 0 end)
    assert password == Enum.uniq(password)
  end

  test "generates 2 random passwords - not equal" do
    password = Genex.generate_password
    password2 = Genex.generate_password
    assert password != password2
  end
end
