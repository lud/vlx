defmodule Vlx.MediaServer do
  @moduledoc """
  This module implements a gen server
  """

  use GenServer

  @gen_opts ~w(name timeout debug spawn_opt hibernate_after)a

  def start_link(opts) do
    {gen_opts, opts} = Keyword.split(opts, @gen_opts)
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  defmodule S do
    @enforce_keys [:config, :media]
    defstruct @enforce_keys
  end

  @impl GenServer
  def init(opts) do
    config = fetch_config()
    start_schedule(config)
    {:ok, %S{config: config, media: []}}
  end

  defp fetch_config() do
    %{dir: dir, refresh: refresh} = Map.new(Application.fetch_env!(:vlx, :media))
    %{dir: dir, refresh: refresh}
  end

  defp start_schedule(%{refresh: int}) do
    send(self(), :refresh)
    :timer.send_interval(int, :refresh)
  end

  @impl GenServer
  def handle_info(:refresh, state) do
    media = fetch_media(state)

    if media != state.media do
      TODO.publish_media()
    end

    state = %S{state | media: media}
    {:noreply, state}
  end

  defp fetch_media(%{config: %{dir: dir}}) do
    Vlx.MediaLib.read_dir_tree(dir)
  end
end
