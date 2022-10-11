defmodule Vlx.PubSub do
  @moduledoc """
  A simple topic name registry for pubsub usage.
  """

  def pubsub do
    __MODULE__
  end

  def media_topic do
    "media_list"
  end

  def listen_media do
    Phoenix.PubSub.subscribe(pubsub(), media_topic())
  end

  def publish_media(media) do
    Phoenix.PubSub.broadcast!(pubsub(), media_topic(), {:media_list, media})
  end

  def vlc_status_topic do
    "vlc_status_info"
  end

  def listen_vlc_status do
    Phoenix.PubSub.subscribe(pubsub(), vlc_status_topic())
  end

  def publish_vlc_status(status) do
    Phoenix.PubSub.broadcast!(pubsub(), vlc_status_topic(), {:vlc_status, status})
  end
end
