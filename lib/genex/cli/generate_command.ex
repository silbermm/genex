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

  @type t :: %GenerateCommand{
          length: number(),
          help: boolean(),
          save: boolean()
        }
  defstruct length: 6, help: false, save: false

  @impl true
  def init(argv), do: parse(argv)

  @impl true
  def help(), do: display(@moduledoc)

  @spec parse(list(String.t())) :: GenerateCommand.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(
      strict: [help: :boolean, length: :integer, save: :boolean],
      aliases: [h: :help, s: :save]
    )
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: GenerateCommand.t()
  defp _parse({opts, _, _}) do
    help = Keyword.get(opts, :help, false)
    save = Keyword.get(opts, :save, false)
    length = Keyword.get(opts, :length, 6)
    %GenerateCommand{help: help, save: save, length: length}
  end

  @impl true
  def process(%GenerateCommand{help: true}), do: help()

  def process(%GenerateCommand{save: false, length: length}) do
    length
    |> Passwords.generate()
    |> Diceware.with_colors()
    |> display(mask_line: true)
  end

  def process(%GenerateCommand{save: true, length: length} = command) do
    passphrase = Passwords.generate(length)
    display(Diceware.with_colors(passphrase))

    "Save this password or regenerate:"
    |> choice([yes: "s", regenerate: "r"], color: IO.ANSI.green())
    |> handle_save(passphrase, command)
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
