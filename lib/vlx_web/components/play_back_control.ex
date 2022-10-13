defmodule VlxWeb.Components.PlayBackControl do
  use Phoenix.Component
  alias VlxWeb.Components.Text
  alias VlxWeb.Components.Icons

  def index(assigns) do
    %Vlx.VlcStatus{audio_tracks: audio, sub_tracks: subs, state: playstate} = assigns.vlc_status

    audio_tracks = normalize_audio_tracks(audio)
    sub_tracks = normalize_sub_tracks(subs)

    {smalltop?, title} =
      case assigns.title do
        nil -> {false, "No File"}
        v -> {true, v}
      end

    assigns =
      assign(assigns,
        audio_tracks: audio_tracks,
        sub_tracks: sub_tracks,
        playstate: playstate,
        smalltop?: smalltop?
      )

    ~H"""
    <div>
      <Text.page_header title={@title} smalltop={if(@smalltop?, do: "Now Playing")} break={true} />

      <Text.section_header title="Audio" icon="audio" />
      <.render_audio_tracks tracks={@audio_tracks} />

      <Text.section_header title="Subtitles" icon="subtitles" />
      <.render_sub_tracks tracks={@sub_tracks} />

      <.playback_buttons playstate={@playstate} fullscreen={@vlc_status.fullscreen} />

    </div>
    """
  end

  defp render_audio_tracks(assigns) do
    ~H"""
    <ul>
      <%= for %{id: id, label: label, selected: sel} <- @tracks do %>
        <li
          class={"p-2 my-1 border border-gray-500 rounded cursor-pointer #{if(sel, do: "text-orange-500", else: "")}"}
          phx-click="set_audio" phx-value-id={id}
          ><%= label %></li>
      <% end %>
      <li
          class={"p-2 my-1 border border-gray-500 rounded cursor-pointer"}
          phx-click="set_audio" phx-value-id={-1}
          >Disable</li>
    </ul>
    """
  end

  defp render_sub_tracks(assigns) do
    ~H"""
    <ul>
      <%= for %{id: id, label: label, selected: sel} <- @tracks do %>
        <li
          class={"p-2 my-1 border border-gray-500 rounded cursor-pointer pl-2 #{if(sel, do: "text-orange-500", else: "")}"}
          phx-click="set_subs" phx-value-id={id}
          ><%= label %></li>
      <% end %>
      <li
          class={"p-2 my-1 border border-gray-500 rounded cursor-pointer"}
          phx-click="set_subs" phx-value-id={-1}
          >Disable</li>
    </ul>
    """
  end

  defp playback_buttons(assigns) do
    class = """
    border
    border-orange-600
    dark:border-orange-300
    hover:bg-orange-500
    text-orange-500
    dark:text-orange-300
    hover:text-white
    p-2 m-2
    flex flex-row
    rounded\
    """

    assigns = assign(assigns, :class, class)

    ~H"""
    <div class="mt-4 flex flex-row justify-center">
      <button phx-click="pb_rel_seek" phx-value-seek="-10" class={@class}><Icons.large icon="backward" /></button>
      <%= if @playstate == "playing" do %>
        <button phx-click="pb_pause" class={@class}><Icons.large icon="pause" /></button>
      <% else %>
        <button phx-click="pb_play" class={@class}><Icons.large icon="play" /></button>
      <% end %>
      <button phx-click="pb_rel_seek" phx-value-seek="+10" class={@class}><Icons.large icon="forward" /></button>
      <button phx-click="vlc_fullscreen_toggle" class={@class <> "ml-8"}>
        <%= if @fullscreen do %>
          <Icons.large icon="no_fullscreen" />
        <% else %>
          <Icons.large icon="fullscreen" />
        <% end %>
      </button>
    </div>

    """
  end

  defp normalize_audio_tracks(audio) do
    audio
    |> Enum.map(fn {id, info} ->
      label = [
        case info do
          %{"Langue_" => lang} -> lang
          _ -> "Unknown"
        end
      ]

      %{selected: false, id: id, label: label}
    end)
  end

  defp normalize_sub_tracks(subs) do
    subs
    |> Enum.map(fn {id, info} ->
      label = [
        case info do
          %{"Langue_" => lang} -> lang
          _ -> "Unknown"
        end,
        case info do
          %{"Description" => desc} -> [" – ", desc]
          _ -> []
        end
      ]

      %{selected: false, id: id, label: label}
    end)
  end
end
