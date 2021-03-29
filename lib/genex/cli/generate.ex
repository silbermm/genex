defmodule Genex.CLI.Generate do
  @moduledoc """
  genex generate generates a random passphrase
    --help, -h                Prints this help message
    --length  passphrase_size Sets the amount of words to use for the passphrase - Defaults to 6
    --save, -s                Save the passphrase for retrieval later
  """

  import Prompt
  alias __MODULE__
  alias Genex.Passwords
  alias Genex.Data.Credentials

  @type t :: %Generate{
          length: number(),
          help: boolean(),
          save: boolean()
        }
  defstruct length: 6, help: false, save: false

  @doc "init the generate command"
  @spec(init(list(String.t())) :: :ok, {:error, binary()})
  def init(argv) do
    argv
    |> parse()
    |> process()
  end

  @doc "parse the command line arguments for the generate command"
  @spec parse(list(String.t())) :: Generate.t()
  def parse(argv) do
    argv
    |> OptionParser.parse(
      strict: [help: :boolean, length: :integer, save: :boolean],
      aliases: [h: :help, s: :save]
    )
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: Generate.t()
  defp _parse({opts, _, _}) do
    help = Keyword.get(opts, :help, false)
    save = Keyword.get(opts, :save, false)
    length = Keyword.get(opts, :length, 6)
    %Generate{help: help, save: save, length: length}
  end

  @spec process(Generate.t()) :: :ok
  defp process(%Generate{help: true}), do: display(@moduledoc)

  defp process(%Generate{save: false, length: length}) do
    passphrase = Passwords.generate(length)
    display(Diceware.with_colors(passphrase))
  end

  defp process(%Generate{save: true, length: length}) do
    passphrase = Passwords.generate(length)
    display(Diceware.with_colors(passphrase))

    "Save this password?"
    |> confirm()
    |> handle_save(passphrase)
  end

  @spec handle_save(:yes | :no | :error, Diceware.Passphrase.t()) :: :ok
  defp handle_save(:no, _password) do
    confirm("Generate a different password")
    :ok
  end

  defp handle_save(:yes, password) do
    account_name = text("Enter an account name that this password belongs to")
    username = text("Enter a username for this account/password")

    account_name
    |> Credentials.new(username, password)
    |> Passwords.save()
  end

  defp handle_save(:error, _passphrase), do: display("Error", error: true)
end
