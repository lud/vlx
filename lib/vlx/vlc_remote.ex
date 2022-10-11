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

  defmacro defcommand(arg1, arg2) do
    binding |> IO.inspect(label: "binding")
    raise "invalid macro call"
  end
end

defmodule Vlx.VlcRemote do
  @moduledoc """
  A process to control VLC with TCP.
  """
  alias Vlx.VlcClient
  use GenServer
  require Logger
  import Vlx.VlcRemote.CompileTime

  @gen_opts ~w(name timeout debug spawn_opt hibernate_after)a

  def start_link(opts) do
    {gen_opts, _opts} = Keyword.split(opts, @gen_opts)
    gen_opts = Keyword.put(gen_opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  def with_client(f) do
    GenServer.call(__MODULE__, {:exec, f}, 20_000)
  end

  defcommand fetch_playback_info(client) do
    raise "todo"
  end

  @impl true
  def init([]) do
    send(self(), :reconnect)
    {:ok, %{status: :disconnected, client: nil}}
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
        Logger.info("successfully connected to VLC")
        {:noreply, %{state | status: :connected, client: client}}

      false ->
        Logger.error("could not connect to VLC")
        Process.send_after(self(), :reconnect, 1000)
        {:noreply, %{state | status: :connected}}
    end
  end
end
