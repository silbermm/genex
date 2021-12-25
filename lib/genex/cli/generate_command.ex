defmodule Genex.CLI.GenerateCommand do
  @moduledoc ~S"""
  genex generate generates a random passphrase
    --help, -h        Prints this help message
    --length <length> Sets the number of words for the passphrase (defaults to 6)
    --save, -s        Save the passphrase for retrieval later
  """
  use Prompt.Command

  alias __MODULE__
  alias Genex.Passwords
  alias Genex.Data.Credentials

  @type t :: %GenerateCommand{
          length: number(),
          help: boolean(),
          save: boolean(),
          cli: Keyword.t()
        }
  defstruct length: 6, help: false, save: false, cli: []

  @impl true
  def init(argv) do
    argv
    |> OptionParser.parse(
      strict: [help: :boolean, length: :integer, save: :boolean],
      aliases: [h: :help, s: :save]
    )
    |> parse()
  end

  @spec parse({list(), list(), list()}) :: t()
  defp parse({opts, _, _}) do
    %GenerateCommand{
      length: Keyword.get(opts, :length, 6),
      save: Keyword.get(opts, :save, false),
      help: Keyword.get(opts, :help, false)
    }
  end

  @impl true
  def process(%GenerateCommand{help: true}), do: help()

  def process(%GenerateCommand{} = command) do
    passphrase = Passwords.generate(command.length)
    display(Diceware.with_colors(passphrase))

    if command.save do
      "Save this password or regenerate:"
      |> choice([yes: "s", regenerate: "r"], color: :green)
      |> handle_save(passphrase, command)
    else
      :ok
    end
  end

  @typep save_opts :: :yes | :regenerate | :error
  @spec handle_save(save_opts(), Diceware.Passphrase.t(), GenerateCommand.t()) ::
          :ok | {:error, any()}
  defp handle_save(:regenerate, _password, command) do
    :ok = Prompt.Position.clear_lines(2)
    process(command)
  end

  defp handle_save(:yes, password, _command) do
    :ok = Prompt.Position.mask_line(2)
    account_name = text("Enter an account name that this password belongs to", trim: true)
    username = text("Enter a username for this account/password", trim: true)

    # account_name
    # |> Credentials.new(username, password)
    # |> Passwords.save()
    :ok
  end

  defp handle_save(:error, _passphrase, _command), do: display("Error", error: true)
end
