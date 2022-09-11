defmodule VlxWeb.Components.MediaList do
  use Phoenix.Component

  alias Vlx.MediaLib.{MFile, MDir}

  def index(assigns) do
    case assigns.media do
      [] ->
        ~H"""
        <div>No media found</div>
        """

      list ->
        ~H"""
        <div><%= render_list_recursive(%{media: list}) %></div>
        """
    end
  end

  defp render_list_recursive(assigns) do
    ~H"""
    <ul>
    <%= for item <- @media do %>
      <%= case item do %>
      <% %MFile{name: name} -> %>
          <li>
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
