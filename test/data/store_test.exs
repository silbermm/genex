defmodule Genex.StoreTest do
  use ExUnit.Case, async: false

  alias Genex.Passwords.Store

  setup :clean_up_passwords_file

  defp passwords_file(), do: Application.get_env(:genex, :genex_home) <> "/passwords"

  test "save passwords file" do
    start_supervised(Store)
    # save some data to table
    Store.save_credentials("account", "username", "2020", "creds")
    assert Store.save_file() == :ok
  end

  test "saves file on exit" do
    start_supervised(Store)
    Store.save_credentials("account", "username", "2020", "creds")
    stop_supervised(Store)
    assert File.exists?(passwords_file())
  end

  test "saves file on other exits" do
    {:ok, pid} = start_supervised(Store)
    Store.save_credentials("account", "username", "2020", "creds")
    Process.exit(pid, "because")
    assert File.exists?(passwords_file())
  end

  test "saves file on any info messate" do
    {:ok, pid} = start_supervised(Store)
    Store.save_credentials("account", "username", "2020", "creds")
    Process.send(pid, "because", [])
    assert File.exists?(passwords_file())
  end

  test "loads file if already exists" do
    start_supervised(Store)
    Store.save_credentials("account", "username", "2020", "creds")
    stop_supervised(Store)
    assert File.exists?(passwords_file())
    start_supervised(Store)
    assert Store.find_account("account") == [{"account", "username", "2020", "creds"}]
  end

  defp clean_up_passwords_file(_context) do
    # start the suite without a password file
    if File.exists?(passwords_file()) do
      File.rm(passwords_file())
    end

    :ok
  end
end
