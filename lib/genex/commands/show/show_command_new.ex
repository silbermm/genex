defmodule Genex.Commands.Show.New do
  @moduledoc """
  Rendering for creating a new password in the TUI
  """

  import Ratatouille.View

  alias __MODULE__

  @type t :: %New{
          show: boolean(),
          current_field: :account | :password | :username,
          account: String.t(),
          username: String.t(),
          password: Diceware.Passphrase.t() | nil
        }

  defstruct show: false, current_field: :account, account: "", username: "", password: nil

  def render(new_model) do
    overlay do
      panel title: "Create a New Password - ESC to cancel" do
        label(content: title(new_model) <> ": " <> current_field(new_model) <> "▌")
      end
    end
  end

  def default(), do: %New{}

  def current_field(%New{current_field: :account, account: account}), do: account
  def current_field(%New{current_field: :username, username: username}), do: username

  def current_field(%New{current_field: :password, password: password}) do
    password.phrase
  end

  def show(new_model) do
    %{new_model | show: true}
  end

  def delete_character(%New{current_field: :account, account: account} = new_model) do
    %{new_model | account: _delete(account)}
  end

  def delete_character(%New{current_field: :username, username: username} = new_model) do
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

  def update(%New{current_field: :account} = new_model, value) do
    %{new_model | account: new_model.account <> value}
  end

  def update(%New{current_field: :username} = new_model, value) do
    %{new_model | username: new_model.username <> value}
  end

  def update(%New{current_field: :password} = new_model, _value) do
    value = Diceware.generate()
    %{new_model | password: value}
  end

  def next(%New{current_field: :account} = new_model), do: %{new_model | current_field: :username}

  def next(%New{current_field: :username} = new_model) do
    phrase = Diceware.generate()
    %{new_model | current_field: :password, password: phrase}
  end

  def next(%New{current_field: :password} = new_model) do
    # save the password
    psswd = Genex.Passwords.Password.new(new_model.account, new_model.username)
    _ = Genex.Passwords.save(psswd, new_model.password)
    default()
  end

  def save(new_model) do
    psswd = Genex.Passwords.Password.new(new_model.account, new_model.username)

    case Genex.Passwords.save(psswd, new_model.password) do
      {:ok, saved} -> {default(), saved}
      {:error, _} -> save(new_model)
    end
  end

  defp title(new_model) do
    case new_model.current_field do
      :password -> "PASSWORD - [r to regenerate]"
      field -> String.capitalize(to_string(field))
    end
  end
end
