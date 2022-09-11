defmodule VlxWeb.RCLive do
  use Phoenix.LiveView
  require Logger

  alias VlxWeb.Components.MediaList
  alias VlxWeb.Components.PlayBackControl
  alias Vlx.VLCRemote
  alias Vlx.VLCCom

  def mount(_params, _, socket) do
    media =
      if connected?(socket) do
        :ok = Vlx.MediaServer.subscribe()
        Vlx.MediaServer.fetch_media!()
      else
        []
      end

    {:ok, assign(socket, media: media, title: "Loading", subs_tracks: [], audio_tracks: [])}
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

  defp refresh(socket) do
    data = VLCRemote.fetch_payback_info()
    assign(socket, data)
  end

  def handle_event("play", %{"path" => path}, socket) do
    Logger.info("now playing #{path}")
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
