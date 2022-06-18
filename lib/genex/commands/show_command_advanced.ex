defmodule Genex.Commands.ShowCommandAdvanced do
  @behaviour Ratatouille.App

  import Ratatouille.View

  @impl true
  def init(_context) do
    # get all passwords from the database
    case Genex.Passwords.all() do
      {:ok, data} -> data
      {:error, _reason} -> []
    end
  end

  @impl true
  def update(model, msg) do
    case msg do
      # {:event, %{ch: ?+}} -> model + 1
      # {:event, %{ch: ?-}} -> model - 1
      _ -> model
    end
  end

  @impl true
  def render(model) do
    view do
      for pass <- model do
        row do
          column(
            [size: 4],
            label(content: "#{pass.account}")
          )

          column([size: 4], label(content: "#{pass.username}"))
          column([size: 4], label(content: "#######"))
          column([size: 4], label(content: "#{pass.timestamp}"))
        end
      end
    end
  end
end
