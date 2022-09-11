defmodule VlxWeb.RCLive do
  use Phoenix.LiveView

  alias VlxWeb.Components.MediaList

  def mount(_params, _, socket) do
    media =
      if connected?(socket) do
        :ok = Vlx.MediaServer.subscribe()
        Vlx.MediaServer.fetch_media!()
      else
        []
      end

    {:ok, assign(socket, media: media)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex">
      <MediaList.index media={@media} />
      <MediaList.index media={@media} />
    </div>
    """
  end

  def handle_info({:media_list, media}, socket) do
    {:noreply, assign(socket, media: media)}
  end
end
