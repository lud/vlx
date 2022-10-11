defmodule Vlx.RCMonitor do
  @moduledoc """
  Implements a simple process that manages the updates of the media library and
  the VLC status where liveview clients register themselves.

  Media and VLC statuses are only ran if there are some registered clients.
  """
  use GenServer
  require Logger

  @gen_opts ~w(name timeout debug spawn_opt hibernate_after)a

  def start_link(opts) do
    {gen_opts, opts} = Keyword.split(opts, @gen_opts)
    gen_opts = Keyword.put(gen_opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  def register do
    GenServer.call(__MODULE__, {:register, self()})
  end

  @impl GenServer
  def init([]) do
    # Instead of using monitors we will link to the clients. So we kill them all
    # if this process exits, and they must register again.
    Process.flag(:trap_exit, true)

    media_refresh =
      :vlx
      |> Application.fetch_env!(:media)
      |> Keyword.fetch!(:refresh_interval)

    vlc_refresh = 10_000

    state = %{
      schedules: %{
        media: media_refresh,
        vlc_status: vlc_refresh
      },
      clients: %{}
    }

    start_schedules(state)
    schedule_now(state)

    {:ok, state}
  end

  defp start_schedules(%{schedules: skeds}) do
    Enum.each(skeds, fn {name, interval} ->
      :timer.send_interval(interval, {:refresh, name, false})
    end)
  end

  defp schedule_now(%{schedules: skeds}, force? \\ false) do
    Enum.each(skeds, fn {name, _interval} ->
      send(self(), {:refresh, name, force?})
    end)
  end

  @impl true
  def handle_call({:register, pid}, _, state) do
    first_client? = map_size(state.clients) == 0
    state = put_in(state.clients[pid], true)

    Process.link(pid)

    if first_client? do
      schedule_now(state, true)
    end

    {:reply, :ok, state}
  end

  @impl true

  # def handle_info({:refresh, name}, state) when map_size(state.clients) == 0 do
  #   Logger.debug("ignored refresh for #{name}: no client")
  #   {:noreply, state}
  # end

  def handle_info({:refresh, name, force?}, state) do
    refresh(name, force?)
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, reason}, state) do
    Logger.debug("RCMonitor client #{inspect(pid)} exit with reason: #{inspect(reason)}")
    {_, state} = pop_in(state.clients[pid])
    {:noreply, state}
  end

  defp refresh(:media, force?) do
    Vlx.MediaServer.publish_media(force?)
  end

  defp refresh(:vlc_status, force?) do
    Vlx.VlcRemote.publish_status(force?)
  end

  defp refresh(name, _) do
    Logger.error("no refresh implementation defined for #{inspect(name)}")
  end
end
