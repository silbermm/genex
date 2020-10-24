defmodule GenexTest.CLI do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Genex.CLI

  @passwords_file Application.get_env(:genex, :passwords_file)

  def clean_up_passwords_file(_context) do
    # start the suite without a password file
    if File.exists?(@passwords_file) do
      File.rm(@passwords_file)
    end

    gmail = Genex.Data.Credentials.new("gmail", "user", "pass")
    Genex.save_credentials(gmail)
    :ok
  end

  setup_all :clean_up_passwords_file

  test "prints help message" do
    assert capture_io(fn -> CLI.main(["--help"]) end) =~ "Password Manager"
  end

  test "generates random password" do
    assert capture_io(fn -> CLI.main(["--generate"]) end) =~ "Save this password? (Y/n)"
  end

  describe "passwords exist" do
    test "does not find a password" do
      assert capture_io(fn -> CLI.main(["--find", "facebook"]) end) ==
               "Unable to find a password with that account name\n"
    end
  end
end
