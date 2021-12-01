defmodule Genex.CLI.GenerateCommand do
  @moduledoc """
  genex generate generates a random passphrase
    --help, -h        Prints this help message
    --length <length> Sets the number of words for the passphrase (defaults to 6)
    --save, -s        Save the passphrase for retrieval later
  """
  use Prompt.Command

  alias __MODULE__
  alias Genex.Passwords
  alias Genex.Data.Credentials
  import Genex.Gettext
  import Genex.CLI.Data
  require EEx

  @template ~s"""
    <%= if get(data, :help) do %>
      <%= help() %>
    <% end %>

    <%= if get(data, :password) do %>
      <%= display(get(data, :password))  %>
      <%= if get(data, :save) do %>
        <%=
          "Save this password or regenerate:"
          |> choice([yes: "s", regenerate: "r"], color: :green)
          |> handle_save(get(data, :passphrase), data)
        %>
      <% end %>
    <% end %>
  """

  EEx.function_from_string(:def, :render, @template, [:data])

  @type t :: %GenerateCommand{
          length: number(),
          help: boolean(),
          save: boolean(),
          cli: Keyword.t()
        }
  defstruct length: 6, help: false, save: false, cli: []

  @impl true
  def init(argv), do: parse(argv)

  @spec parse(list(String.t())) :: Keyword.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(
      strict: [help: :boolean, length: :integer, save: :boolean],
      aliases: [h: :help, s: :save]
    )
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: Keyword.t()
  defp _parse({opts, _, _}) do
    Genex.CLI.Data.new()
    |> Genex.CLI.Data.put(:help, Keyword.get(opts, :help, false))
    |> Genex.CLI.Data.put(:save, Keyword.get(opts, :save, false))
    |> Genex.CLI.Data.put(:length, Keyword.get(opts, :length, 6))
  end

  @impl true
  def process([data: [help: true]] = cli), do: render(cli)

  def process(cli) do
    if Genex.CLI.Data.get(cli, :help) do
      render(cli)
    else
      passphrase =
        cli
        |> Genex.CLI.Data.get(:length)
        |> Passwords.generate()

      cli
      |> Genex.CLI.Data.put(:password, Diceware.with_colors(passphrase))
      |> Genex.CLI.Data.put(:passphrase, passphrase)
      |> render()
    end
  end

  @spec handle_save(:yes | :regenerate | :error, Diceware.Passphrase.t(), GenerateCommand.t()) ::
          :ok | {:error, any()}
  defp handle_save(:regenerate, _password, command) do
    :ok = Prompt.Position.clear_lines(2)
    process(command)
  end

  defp handle_save(:yes, password, _command) do
    :ok = Prompt.Position.mask_line(2)
    account_name = text("Enter an account name that this password belongs to")
    username = text("Enter a username for this account/password")

    account_name
    |> Credentials.new(username, password)
    |> Passwords.save()
  end

  defp handle_save(:error, _passphrase, _command), do: display(gettext("Error"), error: true)
end
