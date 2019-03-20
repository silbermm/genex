defmodule GenexTest.CLI do
  use ExUnit.Case
  import ExUnit.CaptureIO 
  alias Genex.CLI

  test "prints help message" do
    assert capture_io(fn -> CLI.main(["--help"]) end) =~ "Password Manager"
  end

  test "generates random password" do
    assert capture_io(fn -> CLI.main(["--generate"]) end) =~ "Save this password (Y/n)?"
  end

  test "finds a password" do
    assert capture_io(fn -> CLI.main(["--find", "gmail"]) end) == "pass\n"
  end

  test "does not find a password" do
    assert capture_io(fn -> CLI.main(["--find", "facebook"]) end) == "Unable to find a password with that account name\n"
  end

end
