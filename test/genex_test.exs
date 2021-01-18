defmodule Genex.Test do
  use ExUnit.Case, async: false
  doctest Genex

  @passwords_file Application.get_env(:genex, :passwords_file)
  @passphrase Diceware.generate()

  def clean_up_passwords_file(_context) do
    # start the suite without a password file
    if File.exists?(@passwords_file) do
      File.rm(@passwords_file)
    end

    start_supervised(Genex.Data.Passwords)
    :ok
  end

  setup :clean_up_passwords_file

  describe "creates file" do
    setup do
      facebook = Genex.Data.Credentials.new("facebook", "me", @passphrase)
      gmail = Genex.Data.Credentials.new("gmail", "user", @passphrase)
      Genex.save_credentials(gmail)
      [new_creds: facebook, used_creds: gmail]
    end

    test "creates file if not exists already", %{new_creds: facebook} do
      assert Genex.save_credentials(facebook) === :ok
    end

    test "saves credentials", %{new_creds: facebook} do
      assert Genex.save_credentials(facebook) === :ok
    end

    test "find credentials unable to decrypt private key" do
      assert Genex.find_credentials("gmail", "incorrectpassword") === {:error, :password}
    end
  end

  describe "no file" do
    test "find credentials, no file exists" do
      assert Genex.find_credentials("gmail", :noexists) === []
    end
  end

  test "generates random password" do
    password = Genex.generate_password()
    assert Enum.count(password.words) == 6
    assert Enum.all?(password.words, fn p -> String.length(p) > 0 end)
    assert password.words == Enum.uniq(password.words)
  end

  test "generates random password - custom number of words" do
    password = Genex.generate_password(8)
    assert password.count == 8
    assert Enum.all?(password.words, fn p -> String.length(p) > 0 end)
    assert password.words == Enum.uniq(password.words)
  end

  test "generates 2 random passwords - not equal" do
    password = Genex.generate_password()
    password2 = Genex.generate_password()
    assert password != password2
  end
end
