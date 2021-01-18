defmodule Genex.StoreTest do
  use ExUnit.Case, async: false

  alias Genex.Data.Passwords

  @passwords_file Application.get_env(:genex, :passwords_file)

  setup :clean_up_passwords_file

  test "save passwords file" do
    start_supervised(Passwords)
    # save some data to table
    Passwords.save_credentials("account", "username", "2020", "creds")
    assert Passwords.save_file() == :ok
  end

  test "saves file on exit" do
    start_supervised(Passwords)
    Passwords.save_credentials("account", "username", "2020", "creds")
    stop_supervised(Passwords)
    assert File.exists?(@passwords_file)
  end

  test "saves file on other exits" do
    {:ok, pid} = start_supervised(Passwords)
    Passwords.save_credentials("account", "username", "2020", "creds")
    Process.exit(pid, "because")
    assert File.exists?(@passwords_file)
  end

  test "saves file on any info messate" do
    {:ok, pid} = start_supervised(Passwords)
    Passwords.save_credentials("account", "username", "2020", "creds")
    Process.send(pid, "because", [])
    assert File.exists?(@passwords_file)
  end

  test "loads file if already exists" do
    start_supervised(Passwords)
    Passwords.save_credentials("account", "username", "2020", "creds")
    stop_supervised(Passwords)
    assert File.exists?(@passwords_file)
    start_supervised(Passwords)
    assert Passwords.find_account("account") == [{"account", "username", "2020", "creds"}]
  end

  defp clean_up_passwords_file(_context) do
    # start the suite without a password file
    if File.exists?(@passwords_file) do
      File.rm(@passwords_file)
    end

    :ok
  end
end
