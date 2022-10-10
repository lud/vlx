defmodule VlxWeb.RCLive do
  use Phoenix.LiveView
  require Logger

  alias VlxWeb.Components.MediaList
  alias VlxWeb.Components.PlayBackControl
  alias Vlx.VLCRemote
  alias Vlx.Sidekick

  def mount(_params, _, socket) do
    socket =
      assign(socket,
        media: [],
        title: "Loading",
        subs_tracks: [],
        audio_tracks: []
      )

    if connected?(socket) do
      :ok = Vlx.MediaServer.subscribe()
      this = self()

      Sidekick.spawn_task(fn ->
        media = Vlx.MediaServer.fetch_media!()
        send(this, {:media_list, media})
      end)

      send(self(), :refresh)
    end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <PlayBackControl.index title={@title} subs_tracks={@subs_tracks} audio_tracks={@audio_tracks} />
      <MediaList.index media={@media} />
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
    socket = assign(socket, audio_tracks: audio, subs_tracks: subs, title: title)
    {:noreply, socket}
  end

  defp refresh(socket) do
    this = self()

    Sidekick.spawn_task(fn ->
      info = VLCRemote.fetch_payback_info()
      send(this, {:refreshed, info})
    end)

    socket
  end

  def handle_event("play", %{"path" => path}, socket) do
    Logger.info("start playing #{path}")
    :ok = VLCRemote.play(path)
    {:noreply, refresh(socket)}
  end

  def handle_event("set_audio", %{"id" => id}, socket) do
    :ok = VLCRemote.set_audio(id)
    {:noreply, refresh(socket)}
  end

  def handle_event("set_subs", %{"id" => id}, socket) do
    :ok = VLCRemote.set_subs(id)
    {:noreply, refresh(socket)}
  end
end
