defmodule VlxWeb.Components.MediaList do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Vlx.MediaLib.{MFile, MDir}
  alias VlxWeb.Components.Text

  def index(assigns) do
    case assigns.media do
      [] ->
        ~H"""
        <div>
          <Text.section_header title="Media" />
          No media found
        </div>
        """

      list ->
        ~H"""
        <div>
          <Text.section_header title="Media" />
          <%= render_list_recursive(%{media: list}) %>
        </div>
        """
    end
  end

  defp render_list_recursive(assigns) do
    ~H"""
    <ul>
    <%= for item <- @media do %>
      <%= case item do %>
      <% %MFile{name: name, path: path} -> %>
          <li phx-click={JS.push("play", value: %{path: path})}>
            <span class="media-file"><%= name %></span>
          </li>
        <% %MDir{name: name, children: children} -> %>
          <li>
            <span class="media-dir"><%= name %></span>
            <%= render_list_recursive(%{media: children}) %>
          </li>
      <% end %>
    <% end %>
    </ul>
    """
  end
end
