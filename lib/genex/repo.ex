defmodule Genex.Repo do
  use Ecto.Repo,
    otp_app: :genex,
    adapter: Ecto.Adapters.SQLite3
end
