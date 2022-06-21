defmodule Genex.Commands.ShowCommandAdvanced do
  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants

  @impl true
  def init(_context) do
    # get all passwords from the database
    case Genex.Passwords.all() do
      {:ok, data} ->
        %{data: data, current_row: -1, show_password_for_current_row: false}

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

  @impl true
  def update(model, msg) do
    case msg do
      {:event, %{ch: ?k}} ->
        model
        |> move_up_a_row()
        |> reset_show_password

      {:event, %{key: 65517}} ->
        model
        |> move_up_a_row()
        |> reset_show_password

      {:event, %{key: 65516}} ->
        model
        |> move_down_a_row()
        |> reset_show_password

      {:event, %{ch: ?j}} ->
        model
        |> move_down_a_row()
        |> reset_show_password

      {:event, %{key: 32}} ->
        # space bar
        # toggle current row's password
        %{model | show_password_for_current_row: !model.show_password_for_current_row}

      {:event, %{key: 27}} ->
        # escape key
        # hide the current row's password
        %{model | show_password_for_current_row: false}

      _ ->
        model
    end
  end

  @impl true
  def render(%{data: data, current_row: current_row} = model) do
    view bottom_bar: bottom_bar() do
      panel do
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
              table_cell(content: maybe_show_password(model, row))
              table_cell(content: "#{pass.timestamp}")
            end
          end
        end
      end
    end
  end

  defp maybe_show_password(model, row) do
    if model.show_password_for_current_row and row == model.current_row do
      password = Enum.at(model.data, model.current_row, nil)
      password.account
    else
      "*******"
    end
  end

  defp bottom_bar() do
    bar do
      label(content: "SHOW COMMANDS THAT CAN BE USED")
    end
  end
end
