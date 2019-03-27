defmodule GenexInterfaceWeb.IndexLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <form phx-change="update_txt">
      <input type="text" name="txt" value="<%= @txt %>" onchange="this.blur()" />
    </form>
    <div> 
      <h1> <%= @txt %> </h1>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, socket |> assign(%{txt: "hello"})}
  end

  def handle_event("update_txt", %{"txt" => new_txt}, socket) do
    socket = socket |> assign(%{txt: new_txt})
    {:noreply, socket}
  end

end
