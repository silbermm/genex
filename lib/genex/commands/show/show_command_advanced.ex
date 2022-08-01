defmodule Genex.Commands.ShowCommandAdvanced do
  @moduledoc """
  The full screen GUI for showing passwords
  """

  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants

  alias Ratatouille.Runtime.Command
  alias Genex.Commands.Show.New
  alias Genex.Commands.Show.HelperPanel

  @impl true
  def init(context) do
    # read the config async
    get_config = Command.new(fn -> Genex.AppConfig.read() end, :fetch_config)

    # get all passwords from the database
    case Genex.Passwords.all() do
      {:ok, data} ->
        {%{
           data: data,
           current_row: -1,
           show_password_for_current_row: "",
           show_password_error_for_current_row: "",
           copied: "",
           new_model: New.default(),
           helper_panel: nil
         }, get_config}

      {:error, _reason} ->
        %{}
    end
  end

  defp move_up_a_row(%{current_row: 0} = model), do: model
  defp move_up_a_row(model), do: %{model | current_row: model.current_row - 1}

  defp move_down_a_row(%{current_row: row, data: data} = model) when length(data) == row + 1,
    do: model

  defp move_down_a_row(model), do: %{model | current_row: model.current_row + 1}

  defp reset_show_password(model), do: %{model | show_password_for_current_row: ""}

  defp decrypt_current_row_password(model) do
    password = Enum.at(model.data, model.current_row)

    case Genex.Passwords.decrypt(password) do
      {:ok, decrypted} ->
        %{model | show_password_for_current_row: decrypted}

      {:error, reason} ->
        %{model | show_password_error_for_current_row: reason}
    end
  end

  defp delete_previous_charactor(model) do
    updated = New.delete_character(model.new_model)
    %{model | new_model: updated}
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
      {:event, %{ch: ?k}} when model.new_model.show == false ->
        model
        |> move_up_a_row
        |> reset_show_password

      {:event, %{key: 65_517}} when model.new_model.show == false ->
        model
        |> move_up_a_row
        |> reset_show_password

      {:event, %{key: 65_516}} when model.new_model.show == false ->
        model
        |> move_down_a_row
        |> reset_show_password

      {:event, %{ch: ?j}} when model.new_model.show == false ->
        model
        |> move_down_a_row
        |> reset_show_password

      {:event, %{ch: ?c}} when model.new_model.show == false ->
        copy_password(model)

      {:event, %{ch: ?n}} when model.new_model.show == false ->
        %{model | new_model: New.show(model.new_model)}

      {:event, %{ch: ?+}} when model.new_model.show == false ->
        %{model | new_model: New.show(model.new_model)}

      {:event, %{key: 32}} when model.new_model.show == false ->
        # space bar
        # toggle current row's password when we are not showing the new password modal
        decrypt_current_row_password(model)

      {:event, %{key: 27}} ->
        # escape key
        # hide the current row's password and other overlays
        %{
          model
          | show_password_for_current_row: "",
            show_password_error_for_current_row: "",
            copied: "",
            new_model: New.default()
        }

      {:event, %{key: 127}} when model.new_model.show == true ->
        # backspace key
        # delete the previous charactor when we are showing the new password modal
        delete_previous_charactor(model)

      {:event, %{key: 13}} when model.new_model.current_field == :password ->
        # enter key
        # save the password
        {updated, psswd} = New.save(model.new_model)
        %{model | new_model: updated, data: model.data ++ [psswd]}

      {:event, %{key: 13}} when model.new_model.show == true ->
        # enter key
        # save the field
        updated = New.next(model.new_model)
        %{model | new_model: updated}

      {:event, %{ch: ?r}} when model.new_model.current_field == :password ->
        # when r is pressed on the password field, generate a password
        updated = New.update(model.new_model, nil)
        %{model | new_model: updated}

      {:event, %{ch: ?e}} when model.new_model.current_field == :password ->
        # @TODO when e is pressed on the password field, allow the user to edit the passphrase
        updated = New.update(model.new_model, nil)
        %{model | new_model: updated}

      {:event, %{ch: ch}} when ch > 0 and model.new_model.current_field != :password ->
        updated = New.update(model.new_model, <<ch::utf8>>)
        %{model | new_model: updated}

      {:fetch_config, {:ok, config}} ->
        %{model | helper_panel: HelperPanel.default(config)}

      other ->
        model
    end
  end

  @impl true
  def render(%{data: data, current_row: current_row} = model) do
    view bottom_bar: bottom_bar() do
      # TODO: top panel to show help and other commands
      if model.helper_panel != nil do
        HelperPanel.render(model.helper_panel)
      end

      panel title: "GENEX", height: :fill do
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
              table_cell(content: "#{format_timestamp(pass.timestamp)}")
            end
          end
        end
      end

      if model.new_model.show do
        New.render(model.new_model)
      end

      if model.show_password_for_current_row != "" do
        show_password_overlay(model.show_password_for_current_row)
      end

      if model.show_password_error_for_current_row != "" do
        show_password_error(model.show_password_error_for_current_row)
      end

      if model.copied != "" do
        show_copied_success_overlay(model.copied)
      end
    end
  end

  defp format_timestamp(%DateTime{day: d, month: m, year: y, hour: hh, minute: mm}) do
    "#{prefix_with_zero(m)}/#{prefix_with_zero(d)}/#{y} #{prefix_with_zero(hh)}:#{prefix_with_zero(mm)}"
  end

  defp prefix_with_zero(<<number::binary-size(1), _::binary>>), do: "0#{number}"
  defp prefix_with_zero(number) when number < 10, do: "0#{number}"
  defp prefix_with_zero(number), do: number

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
        content: "[j/k or ↑/↓ to move] [space to show] [c to copy] [q to quit] [? for more help]"
      )
    end
  end
end
