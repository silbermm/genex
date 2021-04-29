defmodule GenexTest.CLI do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Genex.CLI

  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  @passphrase Diceware.generate()

  def clean_up_passwords_file(_context) do
    passwords_file = Application.get_env(:genex, :genex_home) <> "/passwords"

    if File.exists?(passwords_file) do
      File.rm(passwords_file)
    end

    start_supervised(Genex.Passwords.Store)

    gmail = Genex.Data.Credentials.new("gmail", "user", @passphrase)
    Genex.Passwords.save(gmail)
    :ok
  end

  setup_all :clean_up_passwords_file

  test "prints help message" do
    assert capture_io(fn -> CLI.main(["--help"]) end) =~ "Passphrase generator"
  end

  test "generates random password" do
    assert capture_io("r\n", fn -> CLI.main(["generate", "-s"]) end) =~
             "Save this password or regenerate: (S/r)"
  end

  test "does not find a password" do
    assert capture_io(fn -> CLI.main(["show", "facebook"]) end) =~
             "Unable to find a password with that account name"
  end
end
