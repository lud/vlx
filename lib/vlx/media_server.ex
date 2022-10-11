defmodule Vlx.MediaServer do
  @moduledoc """
  This module implements a gen server that will monitor the list of media files
  and publish this list.
  """

  use GenServer
  require Logger

  @pubsub_topic "media_list"
  @pubsub Vlx.PubSub

  @gen_opts ~w(name timeout debug spawn_opt hibernate_after)a

  def start_link(opts) do
    {gen_opts, opts} = Keyword.split(opts, @gen_opts)
    gen_opts = Keyword.put(gen_opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @pubsub_topic)
  end

  def fetch_media! do
    GenServer.call(__MODULE__, :fetch)
  end

  defmodule S do
    @enforce_keys [:config, :media]
    defstruct @enforce_keys
  end

  @impl GenServer
  def init(_opts) do
    config = fetch_config()
    start_schedule(config)
    {:ok, %S{config: config, media: []}}
  end

  @impl GenServer
  def handle_info(:refresh, state) do
    Logger.info("refreshing media list")
    media = fetch_media(state)
    len = length(media)
    Logger.info("#{len} media found")

    if media != state.media do
      publish_media(media)
    end

    state = %S{state | media: media}
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:fetch, _, state) do
    {:reply, state.media, state}
  end

  defp fetch_config() do
    %{dir: dir, refresh: refresh} = Map.new(Application.fetch_env!(:vlx, :media))
    %{dir: Path.absname(dir), refresh: refresh}
  end

  defp start_schedule(%{refresh: int}) do
    send(self(), :refresh)
    IO.inspect(int, label: "refresh")
    :timer.send_interval(int, :refresh)
  end

  defp fetch_media(%{config: %{dir: dir}}) do
    dir
    |> Vlx.MediaLib.read_dir_tree()
    |> Vlx.MediaLib.keep_exts(["mov", "avi", "mkv", "mp3"])
    |> Vlx.MediaLib.sort_by_name()
  end

  defp publish_media(media) do
    Phoenix.PubSub.broadcast!(@pubsub, @pubsub_topic, {:media_list, media})
  end
end
