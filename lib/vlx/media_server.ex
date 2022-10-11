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

  def subscribe do
    GenServer.call(__MODULE__, {:subscribe, self()})
  end

  def fetch_media! do
    GenServer.call(__MODULE__, :fetch)
  end

  defmodule S do
    @enforce_keys [:config, :media, :clients]
    defstruct @enforce_keys
  end

  @impl GenServer
  def init(_opts) do
    config = fetch_config()
    start_schedule(config)
    {:ok, %S{config: config, media: [], clients: %{}}}
  end

  @impl GenServer

  def handle_info(:refresh, state) when map_size(state.clients) == 0 do
    state.clients |> IO.inspect(label: "state.clients norefresh")
    {:noreply, state}
  end

  def handle_info(:refresh, state) do
    Logger.info("refreshing media list")
    media = fetch_media(state)
    len = length(media)
    Logger.info("#{len} media found")

    changed? = media != state.media

    state = %S{state | media: media}

    if changed?, do: publish_media(state)

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _, _}, state) when is_map_key(state.clients, ref) do
    {_, state} = pop_in(state.clients[ref])
    state.clients |> IO.inspect(label: "clients")
    {:noreply, state}
  end

  @impl GenServer

  def handle_call(:fetch, _, state) do
    {:reply, state.media, state}
  end

  def handle_call({:subscribe, pid}, _, state) do
    ref = Process.monitor(pid)
    state = put_in(state.clients[ref], pid)
    state |> IO.inspect(label: "state")
    send(self(), :refresh)
    state.clients |> IO.inspect(label: "clients")
    {:reply, :ok, state}
  end

  defp fetch_config() do
    %{dir: dir, refresh: refresh} = Map.new(Application.fetch_env!(:vlx, :media))
    %{dir: Path.absname(dir), refresh: refresh}
  end

  defp start_schedule(%{refresh: int}) do
    send(self(), :refresh)
    :timer.send_interval(int, :refresh)
  end

  defp fetch_media(%{config: %{dir: dir}}) do
    dir
    |> Vlx.MediaLib.read_dir_tree()
    |> Vlx.MediaLib.keep_exts(["mov", "avi", "mkv", "mp3"])
    |> Vlx.MediaLib.sort_by_name()
  end

  defp publish_media(state) do
    media = state.media
    Enum.each(state.clients, fn {_ref, pid} -> send(pid, {:media_list, media}) end)
  end
end
