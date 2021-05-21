defmodule Genex.CLI.CertificatesCommand do
  @moduledoc """
  #{IO.ANSI.green()}genex certs#{IO.ANSI.reset()}
  Generate public and private key certificates

    --print, -p   Prints the public key to stdout
    --help,  -h   Prints this help message
  """
  use Prompt.Command

  alias __MODULE__
  @encryption Application.compile_env!(:genex, :encryption_module)
  @type t :: %CertificatesCommand{help: boolean(), print: boolean()}
  defstruct(help: false, print: false)

  @impl true
  def init(argv), do: parse(argv)

  @impl true
  def process(%CertificatesCommand{help: true}), do: help()

  def process(%CertificatesCommand{print: true}) do
    public_key = @encryption.local_public_key()
    display(public_key)
  end

  def process(%CertificatesCommand{}) do
    display(
      [
        "",
        "Your private key will be protected by a password.",
        "Be sure to remember this one very important password",
        "If forgotten, all of your Genex data will be lost.\n"
      ],
      color: IO.ANSI.green()
    )

    password = password("Enter a password")
    create_certs(password)
  end

  @spec parse(list(String.t())) :: CertificatesCommand.t()
  defp parse(argv) do
    argv
    |> OptionParser.parse(
      strict: [help: :boolean, print: :boolean],
      aliases: [h: :help, p: :print]
    )
    |> _parse()
  end

  @spec _parse({list(), list(), list()}) :: CertificatesCommand.t()
  defp _parse({[help: true], _, _}), do: %CertificatesCommand{help: true}
  defp _parse({[print: true], _, _}), do: %CertificatesCommand{print: true}
  defp _parse({_, _, _}), do: %CertificatesCommand{print: false, help: false}

  @spec create_certs(String.t(), boolean) :: :ok | {:error, any()}
  defp create_certs(password, overwrite \\ false) do
    case Genex.Encryption.OpenSSL.create_certs(password, overwrite) do
      {:error, :ekeyexists} ->
        display("Keys already exist!\n", color: IO.ANSI.red())

        answer =
          confirm("Do you want to overwrite existing keys?",
            default_answer: :no
          )

        if answer == :yes do
          create_certs(password, true)
        else
          {:error, "Won't create certs"}
        end

      :ok ->
        display("Keys created successfully", position: :left)

      {:error, err} ->
        display("something went wrong #{inspect(err)}")
        {:error, err}
    end
  end
end
