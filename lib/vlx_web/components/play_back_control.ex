defmodule VlxWeb.Components.PlayBackControl do
  use Phoenix.Component
  alias VlxWeb.Components.Text

  def index(assigns) do
    ~H"""
    <div>
      <Text.page_header title={@title} smalltop={if(@title != "Loading", do: "Now Playing")} break={true} />

      <Text.section_header title="Audio" />
      <%= render_audio_tracks(%{tracks: @audio_tracks}) %>

      <Text.section_header title="Subtitles" />
      <%= render_subs_tracks(%{tracks: @subs_tracks}) %>

    </div>
    """
  end

  defp render_audio_tracks(assigns) do
    ~H"""
    <ul>
      <%= for %{id: id, label: label, selected: sel} <- @tracks do %>
        <li
          class={"cursor-pointer pl-2 #{if(sel, do: "text-orange-500", else: "")}"}
          phx-click="set_audio" phx-value-id={id}
          ><%= label %></li>
      <% end %>
    </ul>
    """
  end

  defp render_subs_tracks(assigns) do
    ~H"""
    <ul>
      <%= for %{id: id, label: label, selected: sel} <- @tracks do %>
        <li
          class={"cursor-pointer pl-2 #{if(sel, do: "text-orange-500", else: "")}"}
          phx-click="set_subs" phx-value-id={id}
          ><%= label %></li>
      <% end %>
    </ul>
    """
  end
end
