defmodule Genex.Passwords do
  @moduledoc """
  Handles encrypting, decrypting, reading and saving passwords
  """

  alias Genex.AppConfig
  alias Genex.Passwords.Password

  require Logger

  @store Application.compile_env!(:genex, :store)

  @doc """
  """
  @spec generate(integer()) :: Diceware.Passphrase.t()
  def generate(count) do
    Diceware.generate(count: count)
  end

  @doc """
  Deletes a password from the store
  """
  @spec delete(Password.t()) :: {:ok, number()} | {:error, binary()}
  def delete(password) do
    case @store.delete_password(password) do
      :ok -> {:ok, password.id}
      _ -> {:error, :unknown}
    end
  end

  @doc """
  Encrypt a password and save it to the DB
  """
  @spec save(Password.t(), Diceware.Passphrase.t(), map()) :: :ok | {:error, binary()}
  def save(%Password{} = password, %Diceware.Passphrase{} = passphrase, %{
        gpg: %{"email" => gpg_email}
      })
      when gpg_email != "" do
    Logger.debug("Encrypting password for #{gpg_email}")

    # encode the passphrase
    encoded = Jason.encode!(passphrase)

    # encrypt passphrase
    case GPG.encrypt(gpg_email, encoded) do
      {:ok, encrypted} ->
        # add the encrtyped passphrase to the password
        password = Password.add_passphrase(password, encrypted)

        # save the password in storage
        @store.save_password(password)

        Logger.debug("Password saved")
        {:ok, password}

      err ->
        err
    end
  end

  @doc """
  Encrypt a password and save it to the DB
  """
  @spec save(Password.t(), Diceware.Passphrase.t()) :: :ok | {:error, binary()}
  def save(%Password{} = password, %Diceware.Passphrase{} = passphrase) do
    # get config
    case AppConfig.read() do
      {:ok, %{gpg: %{"email" => gpg_email}} = config} when gpg_email != "" ->
        save(password, passphrase, config)

      {:ok, _} ->
        {:error, :no_gpg_email}

      err ->
        err
    end
  end

  @doc """
  Get all passwords
  """
  @spec all :: {:ok, [Password.t()]} | {:error, binary()}
  def all(), do: @store.all_passwords()

  @doc """
  Find a password by the account
  """
  @spec find_by_account(String.t()) :: {:ok, [Password.t()]} | {:error, binary()}
  def find_by_account(account), do: @store.find_password_by(:account, account)

  @spec decrypt(Password.t()) :: {:ok, Diceware.Passphrase.t()} | {:error, binary()}
  def decrypt(%Password{} = password) do
    case GPG.decrypt(password.encrypted_passphrase) do
      {:ok, password} ->
        {:ok,
         password
         |> Jason.decode!()
         |> Diceware.Passphrase.new()}

      e ->
        e
    end
  end
end
