defmodule Genex.CLI.Commands.UI.Edit do
  @moduledoc """
  Rendering for editing an existing password in the TUI
  """
  import Ratatouille.View
  alias Ratatouille.Runtime.Command

  @type t :: %__MODULE__{
          error: nil | String.t(),
          show: boolean(),
          current_row: integer(),
          number_of_rows: integer(),
          words: list()
        }

  defstruct show: false,
            error: nil,
            words: [],
            current_row: 0,
            number_of_rows: 0

  def show(new_model, password),
    do: %{new_model | show: true, number_of_rows: password.count, words: password.words}

  def render(edit_model) do
    overlay do
      panel title: "Edit the Password - ESC to cancel", height: :fill do
        label(content: "Password", attributes: [:bold])

        for {word, row_number} <- Enum.with_index(edit_model.words) do
          row do
            column(size: 12) do
              label(content: show_word(word, row_number, edit_model))
            end
          end
        end

        label(content: "[r to regenerate] [enter to accept]", attributes: [:bold])
      end
    end
  end

  def default(), do: %__MODULE__{}

  def update(model, msg) do
    case msg do
      {:event, %{key: 65_516}} ->
        %{model | edit_model: move_down(model.edit_model)}

      {:event, %{key: 65_517}} ->
        %{model | edit_model: move_up(model.edit_model)}

      {:event, %{key: 27}} ->
        %{model | edit_model: default()}

      {:event, %{key: 127}} ->
        # backspace key
        # delete the previous character when we are showing the new password modal
        %{model | edit_model: delete_previous_character(model.edit_model)}

      {:event, %{key: 13}} ->
        # enter -- save the edited password
        passphrase = Diceware.Passphrase.new(model.edit_model.words)
        password_data = Enum.at(model.data, model.current_row)
        config = model.config
        _ = Genex.Passwords.update(password_data, passphrase, config)
        cmd = Command.new(fn -> Genex.Passwords.all(model.profile) end, :fetch_passwords)

        {%{model | edit_model: default()}, cmd}

      {:event, %{ch: ch}} when ch > 0 ->
        # any character
        %{model | edit_model: add_character(model.edit_model, ch)}

      _ ->
        model
    end
  end

  defp delete_previous_character(edit_model) do
    # word_to_delete_character = Enum.at(edit_model.words, edit_model.current_row)
    words =
      for {word, idx} <- Enum.with_index(edit_model.words) do
        if idx == edit_model.current_row do
          string_length = String.length(word)

          if string_length == 1 do
            ""
          else
            last = string_length - 2
            String.slice(word, 0..last)
          end
        else
          word
        end
      end

    %{edit_model | words: words}
  end

  defp add_character(edit_model, ch) do
    # word_to_delete_character = Enum.at(edit_model.words, edit_model.current_row)
    words =
      for {word, idx} <- Enum.with_index(edit_model.words) do
        if idx == edit_model.current_row do
          word <> <<ch::utf8>>
        else
          word
        end
      end

    %{edit_model | words: words}
  end

  defp move_down(edit_model) do
    if edit_model.number_of_rows - 1 == edit_model.current_row do
      edit_model
    else
      %{edit_model | current_row: edit_model.current_row + 1}
    end
  end

  defp move_up(edit_model) do
    if edit_model.current_row == 0 do
      edit_model
    else
      %{edit_model | current_row: edit_model.current_row - 1}
    end
  end

  defp show_word(word, number, %{current_row: current_row}) do
    if current_row == number do
      word <> "| "
    else
      word
    end
  end
end
