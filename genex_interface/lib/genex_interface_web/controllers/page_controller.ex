defmodule GenexInterfaceWeb.PageController do
  use GenexInterfaceWeb, :controller

  alias Phoenix.LiveView

  def index(conn, _params) do
    conn
    |> LiveView.Controller.live_render(GenexInterfaceWeb.IndexLive, session: %{})
  end

  
end
