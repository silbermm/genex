defmodule Genex.CLI.Support.Core do
  def generate_password(), do: ["random", "password"]

  def find_credentials("gmail", nil), do: [%{password: "pass"}]
  def find_credentials("facebook", nil), do: []
end
