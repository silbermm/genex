defmodule Genex.Core.Test do
  use ExUnit.Case, async: false
  doctest Genex.Core

  @passwords_file Application.get_env(:genex_cli, :passwords_file)

  def clean_up_passwords_file(context) do
    # start the suite without a password file
    if File.exists?(@passwords_file) do
      File.rm(@passwords_file)
    end

    :ok
  end

  setup_all :clean_up_passwords_file

  describe "creates file" do
    setup do
      facebook = Genex.Core.Credentials.new("facebook", "me", "passw0rd")
      gmail = Genex.Core.Credentials.new("gmail", "user", "pass")
      Genex.Core.save_credentials(gmail)
      [new_creds: facebook, used_creds: gmail]
    end

    test "creates file if not exists already", %{new_creds: facebook} do
      assert Genex.Core.save_credentials(facebook) === :ok
    end

    test "saves credentials", %{new_creds: facebook} do
      assert Genex.Core.save_credentials(facebook) === :ok
    end

    test "finds credentials in existing file", %{used_creds: gmail} do
      assert Genex.Core.find_credentials("gmail", "password") === [gmail]
    end

    test "find credentials unable to decrypt private key" do
      assert Genex.Core.find_credentials("gmail", "incorrectpassword") === {:error, :password}
    end
  end

  describe "no file" do
    setup :clean_up_passwords_file

    test "find credentials, no file exists" do
      assert Genex.Core.find_credentials("gmail", :noexists) === :error
    end
  end

  test "generates random password" do
    password = Genex.Core.generate_password()
    assert Enum.count(password) == 6
    assert Enum.all?(password, fn p -> String.length(p) > 0 end)
    assert password == Enum.uniq(password)
  end

  test "generates random password - custom number of words" do
    password = Genex.Core.generate_password(8)
    assert Enum.count(password) == 8
    assert Enum.all?(password, fn p -> String.length(p) > 0 end)
    assert password == Enum.uniq(password)
  end

  test "generates 2 random passwords - not equal" do
    password = Genex.Core.generate_password()
    password2 = Genex.Core.generate_password()
    assert password != password2
  end
end
