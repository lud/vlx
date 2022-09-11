defmodule Vlx.VLCRemote do
  @moduledoc """
  A process to control VLC with TCP.
  """
  alias Vlx.VLCCom
  use Agent
  require Logger

  @gen_opts ~w(name timeout debug spawn_opt hibernate_after)a

  def start_link(opts) do
    {gen_opts, opts} = Keyword.split(opts, @gen_opts)
    gen_opts = Keyword.put(gen_opts, :name, __MODULE__)
    Agent.start_link(fn -> connect() end, gen_opts)
  end

  def connect do
    {:ok, com} = VLCCom.connect(config(), 10_000)
    Logger.info("successfully connected to VLC")
    com
  end

  defp exec(f) do
    Agent.get(__MODULE__, f)
  end

  def play(path) do
    exec(fn com -> VLCCom.play(com, path) end)
  end

  def set_audio(id) do
    exec(fn com -> VLCCom.atrack(com, id) end)
  end

  def set_subs(id) do
    exec(fn com -> VLCCom.strack(com, id) end)
  end

  def fetch_payback_info do
    exec(fn com ->
      audio = VLCCom.list_audio_tracks(com)
      subs = VLCCom.list_subs_tracks(com)
      title = VLCCom.get_title(com)
      %{audio_tracks: audio, subs_tracks: subs, title: title}
    end)
  end

  defp config do
    Map.new(Application.fetch_env!(:vlx, :vlc))
  end
end
