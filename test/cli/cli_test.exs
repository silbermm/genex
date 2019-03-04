defmodule GenexTest.CLI do
  use ExUnit.Case
  import ExUnit.CaptureIO 
  alias Genex.CLI

  test "prints help message" do
    assert capture_io(fn -> CLI.main(['help']) end) =~ "Password Manager"
  end
end
