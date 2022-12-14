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
        tab: :playback,
        page_title: nil,
        sub_tracks: [],
        audio_tracks: [],
        vlc_status: Vlx.VlcStatus.empty(),
        last_clicked_audio: nil,
        last_clicked_subs: nil,
        last_clicked_path: nil
      )

    if connected?(socket) do
      :ok = Vlx.IpDisplay.stop_qrcode_display()
      :ok = Vlx.PubSub.listen_media()
      :ok = Vlx.PubSub.listen_vlc_status()
      :ok = Vlx.RCMonitor.register()
    end

    {:ok, socket}
  end

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <Navbar.index current={@tab}/>
      <div class="container p-4 mx-auto">
        <%= case @tab do %>
          <% :playback -> %> <PlayBackControl.index
            title={@page_title}
            vlc_status={@vlc_status}
            last_clicked_audio={@last_clicked_audio}
            last_clicked_subs={@last_clicked_subs}
            />
          <% :media -> %> <MediaList.index media={@media} last_clicked_path={@last_clicked_path} />
        <% end %>
      </div>
    </div>
    """
  end

  def handle_info({:media_list, media}, socket) do
    {:noreply, assign(socket, media: media)}
  end

  def handle_info({:vlc_status, info}, socket) do
    %{title: title} = info
    socket = assign(socket, vlc_status: info, page_title: title)

    {:noreply, socket}
  end

  def handle_info(other, socket) do
    Logger.error("unexepected info: #{inspect(other)}")
    {:noreply, socket}
  end

  def handle_event("play", %{"path" => path}, socket) do
    Logger.info("start playing #{path}")
    # it's bad that we get the status directly since we will receive it through
    # pubsub. We might as well use it from here.
    {:ok, _} = VlcRemote.play_file(path)
    {:noreply, assign(socket, last_clicked_path: path)}
  end

  def handle_event("set_audio", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:ok, _} = VlcRemote.set_audio_track(id)
    {:noreply, assign(socket, :last_clicked_audio, id)}
  end

  def handle_event("set_subs", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {:ok, _} = VlcRemote.set_subtitle_track(id)
    {:noreply, assign(socket, :last_clicked_subs, id)}
  end

  def handle_event("pb_play", _, socket) do
    {:ok, _} = VlcRemote.resume_playback()
    {:noreply, assign_status(socket, :state, "playing")}
  end

  def handle_event("pb_pause", _, socket) do
    {:ok, _} = VlcRemote.pause_playback()
    {:noreply, assign_status(socket, :state, "paused")}
  end

  def handle_event("pb_rel_seek", %{"seek" => seek}, socket) do
    {:ok, _} = VlcRemote.relative_seek(String.to_integer(seek))
    {:noreply, socket}
  end

  def handle_event("vlc_fullscreen_toggle", _, socket) do
    {:ok, _} = VlcRemote.toggle_fullscreen()
    {:noreply, assign_status(socket, :fullscreen, not socket.assigns.vlc_status.fullscreen)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab =
      case tab do
        "media" -> :media
        "playback" -> :playback
      end

    {:noreply, assign(socket, :tab, tab)}
  end

  # used for optimistic updates
  defp assign_status(socket, key, value) do
    vlc_status = Map.put(socket.assigns.vlc_status, key, value)
    assign(socket, :vlc_status, vlc_status)
  end
end
