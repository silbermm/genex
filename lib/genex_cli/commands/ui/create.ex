defmodule Genex.CLI.Commands.UI.Create do
  @moduledoc """
  Rendering for creating a new password in the TUI
  """

  import Ratatouille.View

  @type t :: %__MODULE__{
          error: nil | String.t(),
          show: boolean(),
          current_field: :account | :password | :username,
          account: String.t(),
          username: String.t(),
          password: Diceware.Passphrase.t() | nil
        }

  defstruct show: false,
            current_field: :account,
            account: "",
            username: "",
            password: nil,
            error: nil

  def render(new_model) do
    overlay do
      panel title: "Create a New Password - ESC to cancel", height: :fill do
        label(content: title(new_model) <> ": " <> current_field(new_model) <> "▌")

        if new_model.current_field == :password do
          label(content: "[r to regenerate] [e to edit] [enter to accept]", attributes: [:bold])
        end
      end
    end
  end

  def default(), do: %__MODULE__{}

  def current_field(%__MODULE__{current_field: :account, account: account}), do: account
  def current_field(%__MODULE__{current_field: :username, username: username}), do: username

  def current_field(%__MODULE__{current_field: :password, password: password}) do
    password.phrase
  end

  def show(new_model) do
    %{new_model | show: true}
  end

  def delete_character(%__MODULE__{current_field: :account, account: account} = new_model) do
    %{new_model | account: _delete(account)}
  end

  def delete_character(%__MODULE__{current_field: :username, username: username} = new_model) do
    %{new_model | username: _delete(username)}
  end

  defp _delete(value) do
    size = String.length(value)
    new_size = size - 1

    case value do
      <<result::binary-size(new_size), _::binary>> -> result
      _ -> value
    end
  end

  def update(new_model, value, opts \\ [])

  def update(%__MODULE__{current_field: :account} = new_model, value, _opts) do
    %{new_model | account: new_model.account <> value}
  end

  def update(%__MODULE__{current_field: :username} = new_model, value, _opts) do
    %{new_model | username: new_model.username <> value}
  end

  def update(%__MODULE__{current_field: :password} = new_model, _value, opts) do
    pass_length = Keyword.get(opts, :password_length, 8)
    value = Diceware.generate(count: pass_length)
    %{new_model | password: value}
  end

  def next(model, opts \\ [])

  def next(%__MODULE__{current_field: :account} = new_model, _),
    do: %{new_model | current_field: :username}

  def next(%__MODULE__{current_field: :username} = new_model, opts) do
    pass_length = Keyword.get(opts, :password_length, 8)
    phrase = Diceware.generate(count: pass_length)
    %{new_model | current_field: :password, password: phrase}
  end

  def next(%__MODULE__{current_field: :password} = new_model, _) do
    # save the password
    #psswd = Genex.Passwords.Password.new(new_model.account, new_model.username)

    case Genex.Passwords.save(new_model.account, new_model.username, new_model.password) do
      :ok -> default()
      {:error, _reason} -> new_model
    end
  end

  def save(new_model, app_config) do
    #psswd = Genex.Passwords.Password.new(new_model.account, new_model.username)

    case Genex.Passwords.save(new_model.account, new_model.username, new_model.password, app_config) do
      {:ok, saved} -> {default(), saved}
      {:error, _} -> save(new_model, app_config)
    end
  end

  defp title(new_model) do
    String.capitalize(to_string(new_model.current_field))
  end
end
