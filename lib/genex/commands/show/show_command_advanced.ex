defmodule Genex.Commands.ShowCommandAdvanced do
  @moduledoc """
  The full screen GUI for showing passwords
  """

  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants

  alias Genex.Commands.Show.New

  @impl true
  def init(_context) do
    # get all passwords from the database
    case Genex.Passwords.all() do
      {:ok, data} ->
        %{
          data: data,
          current_row: -1,
          show_password_for_current_row: false,
          copied: "",
          create_new: false,
          new: %{
            account: "",
            username: "",
            password: ""
          }
        }

      {:error, _reason} ->
        []
    end
  end

  defp move_up_a_row(%{current_row: 0} = model), do: model
  defp move_up_a_row(model), do: %{model | current_row: model.current_row - 1}

  defp move_down_a_row(%{current_row: row, data: data} = model) when length(data) == row + 1,
    do: model

  defp move_down_a_row(model), do: %{model | current_row: model.current_row + 1}

  defp reset_show_password(model), do: %{model | show_password_for_current_row: false}

  defp show_password(model) do
    password = Enum.at(model.data, model.current_row)
    Genex.Passwords.decrypt(password)
  end

  defp copy_password(model) do
    password = Enum.at(model.data, model.current_row)

    case Genex.Passwords.decrypt(password) do
      {:ok, pass} ->
        Clipboard.copy!(pass.phrase)
        %{model | copied: password.account}

      {:error, _} ->
        model
    end
  end

  @impl true
  def update(model, msg) do
    case msg do
      {:event, %{ch: ?k}} when model.create_new == false ->
        model
        |> move_up_a_row()
        |> reset_show_password

      {:event, %{key: 65_517}} when model.create_new == false ->
        model
        |> move_up_a_row()
        |> reset_show_password

      {:event, %{key: 65_516}} when model.create_new == false ->
        model
        |> move_down_a_row()
        |> reset_show_password

      {:event, %{ch: ?j}} when model.create_new == false ->
        model
        |> move_down_a_row()
        |> reset_show_password

      {:event, %{ch: ?c}} when model.create_new == false ->
        model
        |> copy_password()

      {:event, %{ch: ?n}} when model.create_new == false ->
        %{model | create_new: true}

      {:event, %{key: 32}} when model.create_new == false ->
        # space bar
        # toggle current row's password
        %{model | show_password_for_current_row: !model.show_password_for_current_row}

      {:event, %{key: 27}} ->
        # escape key
        # hide the current row's password and other overlays
        %{model | show_password_for_current_row: false, copied: "", create_new: false}

      {:event, %{ch: ch}} when ch > 0 ->
        %{model | new: %{model.new | account: model.new.account <> <<ch::utf8>>}}

      _ ->
        model
    end
  end

  @impl true
  def render(%{data: data, current_row: current_row} = model) do
    view bottom_bar: bottom_bar() do
      panel title: "GENEX" do
        table do
          table_row(background: color(:white), color: color(:black)) do
            table_cell(content: "ACCOUNT")
            table_cell(content: "USERNAME")
            table_cell(content: "PASSWORD")
            table_cell(content: "CREATED")
          end

          for {pass, row} <- Enum.with_index(data) do
            options =
              if row == current_row do
                [background: color(:black), color: color(:white)]
              else
                []
              end

            table_row options do
              table_cell(content: "#{pass.account}")
              table_cell(content: "#{pass.username}")
              table_cell(content: "#{pass.passphrase}")
              table_cell(content: "#{pass.timestamp}")
            end
          end
        end
      end

      if model.create_new do
        New.render(model)
      end

      if model.show_password_for_current_row do
        case show_password(model) do
          {:ok, decrypted} ->
            show_password_overlay(decrypted)

          {:error, reason} ->
            show_password_error(reason)
        end
      end

      if model.copied != "" do
        show_copied_success_overlay(model.copied)
      end
    end
  end

  defp show_password_overlay(decrypted) do
    overlay do
      panel title: "ESC to close / C to copy" do
        label(content: Diceware.with_colors(decrypted) <> IO.ANSI.reset())

        row do
          column size: 9 do
            label(content: "more", color: color(:red))
          end
        end
      end
    end
  end

  defp show_copied_success_overlay(account) do
    overlay do
      panel title: "ESC to close" do
        label(content: "Successfully copied password for " <> account)
      end
    end
  end

  defp show_password_error(reason) do
    overlay padding: 1 do
      panel do
        label(content: reason, color: color(:red))
      end
    end
  end

  defp bottom_bar() do
    bar do
      label(
        content:
          "[j/k or ↑/↓ to move] [space to show password] [c to copy password] [q to quit] [? for more help]"
      )
    end
  end
end
