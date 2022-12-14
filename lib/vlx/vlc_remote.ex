defmodule Vlx.VlcRemote.CompileTime do
  defmacro defcommand({fun_name, _, []}, do: _block) do
    raise "invalid command #{fun_name}, at least one argument is required"
  end

  defmacro defcommand({fun_name, _, [client_arg | args] = all_args}, do: block) do
    impl_name = :"command__#{fun_name}"

    quote do
      def unquote(fun_name)(unquote_splicing(args)) do
        with_client(fn client -> unquote(impl_name)(client, unquote_splicing(args)) end)
      end

      @doc false
      defp unquote(impl_name)(unquote_splicing(all_args)) do
        unquote(block)
      end
    end
    |> tap(&Macro.to_string/1)
  end

  defmacro defcommand(_arg1, _arg2) do
    raise "invalid macro call"
  end

  @doc """
  Takes a list of exported function from Vlx.VlcClient and creates a function
  with arity minus one, forwarding the call to Vlx.VlcRemote.
  """
  defmacro forward_calls(exports) when is_list(exports) do
    quote bind_quoted: [exports: exports] do
      Enum.each(exports, fn {fun, arity} ->
        args = Macro.generate_arguments(arity - 1, Vlx.VlcRemote)

        def unquote(fun)(unquote_splicing(args)) do
          with_client(fn client -> Vlx.VlcClient.unquote(fun)(client, unquote_splicing(args)) end)
        end
      end)
    end
  end
end

defmodule Vlx.VlcRemote do
  @moduledoc """
  A process to control VLC with TCP.
  """
  alias Vlx.VlcClient
  alias Vlx.VlcStatus
  use GenServer
  require Logger
  import Vlx.VlcRemote.CompileTime

  @gen_opts ~w(name timeout debug spawn_opt hibernate_after)a

  def start_link(opts) do
    {gen_opts, _opts} = Keyword.split(opts, @gen_opts)
    gen_opts = Keyword.put(gen_opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc false
  def with_client(f) do
    GenServer.call(__MODULE__, {:exec, f})
  end

  def publish_status(force?) do
    GenServer.call(__MODULE__, {:republish, force?})
  end

  def get_last_status do
    GenServer.call(__MODULE__, :last_status)
  end

  forward_calls(
    connected?: 1,
    empty_playlist: 1,
    get_status: 1,
    pause_playback: 1,
    play_file: 2,
    relative_seek: 2,
    resume_playback: 1,
    set_audio_track: 2,
    set_subtitle_track: 2,
    toggle_fullscreen: 1
  )

  @impl true
  def init([]) do
    send(self(), :reconnect)
    {:ok, %{connstatus: :disconnected, client: nil, vlc_status: Vlx.VlcStatus.empty()}}
  end

  @impl true
  def handle_info(:reconnect, state) do
    Logger.info("connecting to VLC ...")
    config = Application.fetch_env!(:vlx, :vlc)
    port = Keyword.fetch!(config, :port)
    password = Keyword.fetch!(config, :password)
    client = VlcClient.new(host: "localhost", port: port, password: password)

    case VlcClient.connected?(client) do
      true ->
        {:ok, raw_status} = VlcClient.get_status(client)
        state = handle_new_status(raw_status, state, false)
        Logger.info("successfully connected to VLC")
        {:noreply, %{state | connstatus: :connected, client: client}}

      false ->
        Logger.error("could not connect to VLC")
        Process.send_after(self(), :reconnect, 500)
        {:noreply, %{state | connstatus: :disconnected}}
    end
  end

  def handle_info(:force_refresh, state) do
    {:reply, _, state} = handle_call({:republish, true}, nil, state)
    {:noreply, state}
  end

  @impl true

  def handle_call(_, _, %{connstatus: :disconnected} = state) do
    {:reply, {:error, :disconnected}, state}
  end

  def handle_call({:exec, f}, from, state) do
    state =
      case f.(state.client) do
        {:ok, %{"apiversion" => 3}} = reply ->
          # VLC did not update its status from the file when changing file,
          # so we will delay the status update a little bit.
          Process.send_after(self(), :force_refresh, 1000)

          GenServer.reply(from, reply)
          state

        {:error, %Mint.TransportError{reason: :econnrefused}} ->
          send(self(), :reconnect)
          GenServer.reply(from, {:error, :disconnected})
          Logger.error("lost connection to VLC")
          %{state | connstatus: :disconnected}

        other ->
          GenServer.reply(from, other)
          state
      end

    {:noreply, state}
  end

  def handle_call({:republish, force?}, _, state) do
    case Vlx.VlcClient.get_status(state.client) do
      {:ok, raw_status} ->
        state = handle_new_status(raw_status, state, force?)
        {:reply, :ok, state}

      {:error, reason} when force? ->
        {:reply, {:error, reason}, state}

      # in that case we ignore the error
      _other ->
        {:reply, :ok, state}
    end
  end

  def handle_call(:last_status, _, state) do
    {:reply, {:ok, state.vlc_status}, state}
  end

  defp handle_new_status(raw_status, state, force?) do
    vlc_status = compute_status(raw_status)

    if force? or vlc_status != state.vlc_status do
      Vlx.PubSub.publish_vlc_status(vlc_status)
      put_in(state.vlc_status, vlc_status)
    else
      state
    end
  end

  defp compute_status(raw_status) do
    VlcStatus.from_raw(raw_status)
  end
end
