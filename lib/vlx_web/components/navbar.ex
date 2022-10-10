defmodule VlxWeb.Components.Navbar do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Vlx.MediaLib.{MFile, MDir}
  alias VlxWeb.Components.Text

  def index(assigns) do
    ~H"""
    <nav class="bg-white shadow dark:bg-gray-800">
      <div class="container flex items-center justify-between p-6 mx-auto text-gray-600 dark:text-gray-300">
        <div>
          <a class="text-2xl font-mono font-bold text-gray-800 transition-colors duration-300 transform dark:text-white lg:text-3xl hover:text-gray-700 dark:hover:text-gray-300" href="#">vlx</a>
        </div>
        <div>
          <.navlink text="Playback" tab="playback" active={@current == :playback}/>
          <.navlink text="Media" tab="media" active={@current == :media}/>
        </div>
      </div>
    </nav>
    """
  end

  defp navlink(assigns) do
    assigns = Map.put_new(assigns, :active, false)

    ~H"""
    <a href="#"
      phx-click="set_tab" phx-value-tab={@tab}
      class={"
        border-b-2
        #{if @active, do: "border-blue-500", else: "border-transparent"}
        hover:text-gray-800
        transition-colors
        duration-300
        transform
        dark:hover:text-gray-200
        hover:border-blue-500
        mx-1.5 sm:mx-6
      "}
      ><%= @text %></a>
    """
  end
end
