defmodule GenexTest.CLI do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Genex.CLI

  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  @passwords_file Application.get_env(:genex, :passwords_file)
  @passphrase Diceware.generate()

  def clean_up_passwords_file(_context) do
    # start the suite without a password file
    if File.exists?(@passwords_file) do
      File.rm(@passwords_file)
    end

    start_supervised(Genex.Store.ETS)

    gmail = Genex.Data.Credentials.new("gmail", "user", @passphrase)
    Genex.save_credentials(gmail)
    :ok
  end

  setup_all :clean_up_passwords_file

  test "prints help message" do
    assert capture_io(fn -> CLI.main(["--help"]) end) =~ "Password Manager"
  end

  test "generates random password" do
    assert capture_io("n\n", fn -> CLI.main(["--generate"]) end) =~ "Save this password? (Y/n)"
  end

  test "does not find a password" do
    assert capture_io(fn -> CLI.main(["--find", "facebook"]) end) =~
             "Unable to find a password with that account name"
  end
end
