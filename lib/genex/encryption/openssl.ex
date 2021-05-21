defmodule Genex.Encryption.OpenSSL do
  @moduledoc "Creates RSA certs"

  @system Application.compile_env(:genex, :system_module, System)

  @doc "Create public and private certificates"
  def create_certs(password, override \\ false) do
    private_file = Application.get_env(:genex, :genex_home) <> "/private_key.pem"
    public_file = Application.get_env(:genex, :genex_home) <> "/public_key.pem"

    if !override && (File.exists?(private_file) || File.exists?(public_file)) do
      {:error, :ekeyexists}
    else
      case private_key(private_file, password) do
        {_, 0} ->
          public_key(public_file, private_file, password)

        {_, _code} ->
          {:error, :private_key}
      end
    end
  rescue
    _e in ErlangError -> {:error, :enossl}
  end

  defp private_key(private_file, password) do
    @system.cmd(
      "openssl",
      ["genrsa", "-des3", "-passout", "pass:#{password}", "-out", private_file, "4096"],
      stderr_to_stdout: true
    )
  end

  defp public_key(public_key_file, private_key_file, password) do
    res =
      @system.cmd("openssl", [
        "rsa",
        "-in",
        private_key_file,
        "-passin",
        "pass:#{password}",
        "-out",
        public_key_file,
        "-outform",
        "PEM",
        "-pubout"
      ])

    case res do
      {_, 0} -> :ok
      {_, code} -> {:error, :public_key, code}
    end
  end
end
