defmodule Vlx.MediaServer do
  @moduledoc """
  This module implements a gen server that will monitor the list of media files
  and publish this list.
  """

  use GenServer
  require Logger

  @gen_opts ~w(name timeout debug spawn_opt hibernate_after)a

  def start_link(opts) do
    {gen_opts, opts} = Keyword.split(opts, @gen_opts)
    gen_opts = Keyword.put(gen_opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  def publish_media(force?) do
    GenServer.call(__MODULE__, {:publish_media, force?})
  end

  defmodule S do
    @enforce_keys [:config, :media]
    defstruct @enforce_keys
  end

  @impl GenServer
  def init(_opts) do
    config = fetch_config()
    {:ok, %S{config: config, media: []}}
  end

  @impl GenServer
  def handle_call({:publish_media, force?}, _, state) do
    Logger.info("refreshing media list")
    media = fetch_media(state)
    len = count_files(media, 0)
    Logger.info("#{len} media found")

    if force? or media != state.media do
      do_publish_media(media)
    end

    state = %S{state | media: media}
    {:reply, :ok, state}
  end

  defp fetch_config() do
    %{dir: dir} = Map.new(Application.fetch_env!(:vlx, :media))
    %{dir: Path.absname(dir)}
  end

  defp fetch_media(%{config: %{dir: dir}}) do
    dir
    |> Vlx.MediaLib.read_dir_tree()
    |> Vlx.MediaLib.keep_exts(["mov", "avi", "mkv", "mp3"])
    |> Vlx.MediaLib.sort_by_name()
  end

  defp count_files(files, acc) do
    alias Vlx.MediaLib.{MFile, MDir}

    Enum.reduce(files, acc, fn
      %MFile{}, acc -> acc + 1
      %MDir{children: children}, acc -> count_files(children, acc)
    end)
  end

  defp do_publish_media(media) do
    Vlx.PubSub.publish_media(media)
  end
end
