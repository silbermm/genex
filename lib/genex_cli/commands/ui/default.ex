defmodule Genex.CLI.Commands.UI.Default do
  @moduledoc """
  The full screen GUI for managing passwords
  """

  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants

  alias Ratatouille.Runtime.Command
  alias Genex.CLI.Commands.UI.Create
  alias Genex.CLI.Commands.UI.HelperPanel

  require Logger

  # @colors [color(:red), color(:blue), color(:green), color(:yellow)]

  @impl true
  def init(_context) do
    # read the config async
    # @TODO: figure out how to pull the profile name from the cli args (:ets?)
    [{"profile", profile}] = :ets.lookup(:profile_lookup, "profile")

    get_config = Command.new(fn -> Genex.Settings.get(profile) end, :fetch_config)

    # get the passwords async
    get_passwords = Command.new(fn -> Genex.Passwords.all(profile) end, :fetch_passwords)

    {%{
       data: [],
       current_row: -1,
       show_password_for_current_row: "",
       delete_password_for_current_row: false,
       show_password_error_for_current_row: "",
       copied: "",
       new_model: Create.default(),
       helper_panel: nil,
       config: nil,
       syncing: false
     }, Command.batch([get_config, get_passwords])}
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
    updated = Create.delete_character(model.new_model)
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

  defguardp has_passwords(model) when length(model.data) > 0

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

      # copy a password
      {:event, %{ch: ?c}} when model.new_model.show == false and has_passwords(model) ->
        copy_password(model)

      # synchronize
      {:event, %{ch: ?s}} when model.new_model.show == false ->
        sync_passwords =
          Command.new(
            fn ->
              Genex.Passwords.remote_pull_merge(model.config)
            end,
            :sync_passwords_pull
          )

        {%{model | syncing: true}, sync_passwords}

      # create a password
      {:event, %{ch: ?n}} when model.new_model.show == false ->
        %{model | new_model: Create.show(model.new_model)}

      # create a password
      {:event, %{ch: ?+}} when model.new_model.show == false ->
        %{model | new_model: Create.show(model.new_model)}

      # delete a password
      {:event, %{ch: ?d}} when model.new_model.show == false and has_passwords(model) ->
        %{model | delete_password_for_current_row: true}

      # yes, delete password
      {:event, %{key: 13}}
      when model.new_model.show == false and model.delete_password_for_current_row == true ->
        # enter key
        delete_password =
          Command.new(
            fn ->
              password = Enum.at(model.data, model.current_row)
              Genex.Passwords.delete(password)
            end,
            :delete_password
          )

        {%{model | delete_password_for_current_row: false, current_row: 1}, delete_password}

      # toggle current row's password when we are not showing the new password modal
      {:event, %{key: 32}} when model.new_model.show == false and has_passwords(model) ->
        # space bar
        decrypt_current_row_password(model)

      # hide the current row's password and other overlays
      {:event, %{key: 27}} ->
        # escape key
        %{
          model
          | show_password_for_current_row: "",
            show_password_error_for_current_row: "",
            delete_password_for_current_row: false,
            copied: "",
            new_model: Create.default()
        }

      {:event, %{key: 127}} when model.new_model.show == true ->
        # backspace key
        # delete the previous charactor when we are showing the new password modal
        delete_previous_charactor(model)

      {:event, %{key: 13}} when model.new_model.current_field == :password ->
        # enter key
        # save the password
        {updated, psswd} = Create.save(model.new_model, model.config)
        %{model | new_model: updated, data: model.data ++ [psswd]}

      {:event, %{key: 13}} when model.new_model.show == true ->
        # enter key
        # save the field
        updated = Create.next(model.new_model, model.config)
        %{model | new_model: updated}

      {:event, %{ch: ?r}} when model.new_model.current_field == :password ->
        # when r is pressed on the password field, generate a password
        updated =
          Create.update(model.new_model, nil, password_length: model.config.password_length)

        %{model | new_model: updated}

      {:event, %{ch: ?e}} when model.new_model.current_field == :password ->
        # @TODO when e is pressed on the password field, allow the user to edit the passphrase
        updated = Create.update(model.new_model, nil)
        %{model | new_model: updated}

      {:event, %{ch: ch}} when ch > 0 and model.new_model.current_field != :password ->
        updated = Create.update(model.new_model, <<ch::utf8>>)
        %{model | new_model: updated}

      {:fetch_config, config} ->
        %{model | config: config, helper_panel: HelperPanel.default(config)}

      {:fetch_passwords, data} ->
        %{model | data: data}

      {:delete_password, {:ok, password_id}} ->
        data = Enum.reject(model.data, fn d -> d.id == password_id end)
        %{model | data: data, current_row: -1}

      {:sync_passwords_pull, {:ok, latest_passwords}} ->
        # after pulling passwords, push passwords
        Logger.debug("done pulling passwords, now pushing")
        _ = Genex.Passwords.remote_push(model.config)
        %{model | syncing: false, data: latest_passwords}

      {:sync_passwords_pull, err} ->
        # TODO: probably should show an error here at some point
        Logger.error(inspect(err))
        %{model | syncing: false}

      {:sync_passwords_push, :ok} ->
        model

      other ->
        Logger.debug("unhandled keystroke: #{inspect(other)}")
        model
    end
  end

  @impl true
  def render(%{data: data, current_row: current_row} = model) do
    view bottom_bar: bottom_bar() do
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
                [background: color(:cyan), color: color(:black)]
              else
                []
              end

            table_row options do
              table_cell(content: "#{pass.account}")
              table_cell(content: "#{pass.username}")
              table_cell(content: "#{pass.passphrase}")
              table_cell(content: "#{format_timestamp(pass.inserted_at)}")
            end
          end
        end
      end

      if model.new_model.show do
        Create.render(model.new_model)
      end

      if model.delete_password_for_current_row do
        current_password = Enum.at(model.data, model.current_row)

        overlay do
          panel title: "ESC to cancel", height: :fill do
            label do
              text(content: "This will delete the password for #{current_password.account}.")
            end

            label do
              text(
                content: "Are you sure? [Enter to delete / ESC to cancel] ",
                color: color(:red)
              )
            end
          end
        end
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

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end

  defp prefix_with_zero(<<number::binary-size(1), _::binary>>), do: "0#{number}"
  defp prefix_with_zero(number) when number < 10, do: "0#{number}"
  defp prefix_with_zero(number), do: number

  defp show_password_overlay(decrypted) do
    overlay do
      panel title: "ESC to close / C to copy", height: :fill do
        label do
          Genex.CLI.Commands.UI.ColorizedPassphrase.render(decrypted)
        end
      end
    end
  end

  defp show_copied_success_overlay(account) do
    overlay do
      panel title: "ESC to close", height: :fill do
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

  # defp colorized_password(pass) do
  #   number_of_color_lists = div(pass.count, Enum.count(@colors))
  #   extra_colors = rem(pass.count, Enum.count(@colors))

  #   colors =
  #     Enum.reduce(0..number_of_color_lists, [], fn _x, acc ->
  #       acc ++ @colors
  #     end)

  #   color_list = colors ++ Enum.take(@colors, extra_colors)

  #   Enum.with_index(pass.words, fn element, index ->
  #     text(content: element, color: Enum.at(color_list, index))
  #   end)
  # end
end
