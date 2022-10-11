defmodule VlxWeb.RCLive do
  alias Vlx.Sidekick
  alias Vlx.VlcRemote
  alias VlxWeb.Components.MediaList
  alias VlxWeb.Components.Navbar
  alias VlxWeb.Components.PlayBackControl
  require Logger
  use Phoenix.LiveView

  def mount(_params, _, socket) do
    socket =
      assign(socket,
        media: [],
        tab: :media,
        page_title: "Loading",
        subs_tracks: [],
        audio_tracks: []
      )

    if connected?(socket) do
      :ok = Vlx.MediaServer.subscribe()

      send(self(), :refresh)
    end

    {:ok, socket}
  end

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <Navbar.index current={@tab}/>
      <div class="container p-4">
        <%= case @tab do %>
          <% :playback -> %> <PlayBackControl.index title={@page_title} subs_tracks={@subs_tracks} audio_tracks={@audio_tracks} />
          <% :media -> %> <MediaList.index media={@media} />
        <% end %>
      </div>
    </div>
    """
  end

  def handle_info({:media_list, media}, socket) do
    {:noreply, assign(socket, media: media)}
  end

  def handle_info(:refresh, socket) do
    {:noreply, refresh(socket)}
  end

  def handle_info({:refreshed, info}, socket) do
    %{audio_tracks: audio, subs_tracks: subs, title: title} = info
    socket = assign(socket, page_title: title, audio_tracks: audio, subs_tracks: subs)
    {:noreply, socket}
  end

  defp refresh(socket, assigns \\ []) do
    this = self()

    Sidekick.spawn_task(fn ->
      info = VlcRemote.fetch_playback_info()
      send(this, {:refreshed, info})
    end)

    assign(socket, assigns)
  end

  def handle_event("play", %{"path" => path}, socket) do
    Logger.info("start playing #{path}")
    :ok = VlcRemote.play(path)
    {:noreply, refresh(socket, tab: :playback)}
  end

  def handle_event("set_audio", %{"id" => id}, socket) do
    :ok = VlcRemote.set_audio(id)
    {:noreply, refresh(socket)}
  end

  def handle_event("set_subs", %{"id" => id}, socket) do
    :ok = VlcRemote.set_subs(id)
    {:noreply, refresh(socket)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab =
      case tab do
        "media" -> :media
        "playback" -> :playback
      end

    {:noreply, assign(socket, :tab, tab)}
  end
end
