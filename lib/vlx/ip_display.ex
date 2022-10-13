defmodule Vlx.IpDisplay do
  use GenServer, restart: :temporary
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def stop_qrcode_display do
    GenServer.call(__MODULE__, :stop_qr_display, 10_000)
  end

  def init(_arg) do
    ip = find_ip()

    port =
      Application.get_env(:vlx, VlxWeb.Endpoint)
      |> Keyword.fetch!(:http)
      |> Keyword.fetch!(:port)

    case find_ip do
      nil ->
        :ignore

      {a, b, c, d} ->
        state = %{
          url: "http://#{a}.#{b}.#{c}.#{d}:#{port}",
          keep_qr_display: true,
          qr_path: :code.priv_dir(:vlx) |> Path.join("qrcode.png")
        }

        send(self(), :refresh)

        {:ok, state, {:continue, :after_init}}
    end
  end

  def handle_continue(:after_init, state) do
    %{url: url, qr_path: path} = state

    qrcode =
      url
      |> EQRCode.encode()
      |> EQRCode.png()

    path = File.write!(path, qrcode)

    {:noreply, state}
  end

  def handle_info(:refresh, %{qr_path: qr_path, keep_qr_display: keep?} = state) do
    # VLC keeps images for 10 seconds. We will re-add the qr-code every 9
    # seconds (if it fails, retry after 1 second)
    if keep? do
      delay =
        case maybe_send_file(qr_path) do
          :ok -> 9_000
          :error -> 1_000
          :ignore -> false
        end

      if delay do
        Process.send_after(self(), :refresh, delay)
      end
    end

    {:noreply, state}
  end

  def handle_call(:stop_qr_display, _, state) do
    Logger.info("IP Display disabled")
    {:reply, :ok, %{state | keep_qr_display: false}}
  end

  defp maybe_send_file(path) do
    case Vlx.VlcRemote.get_last_status() do
      {:error, :disconnected} ->
        Logger.error("cannot display, error")
        :error

      {:ok, %Vlx.VlcStatus{actual: false} = status} ->
        # this is not a true status from vlc, but a dummy one from
        # initialization, we will retry later
        Logger.debug("ip display waiting for first actual status")
        :error

      {:ok, %Vlx.VlcStatus{title: qrcode, fullscreen: full?}}
      when qrcode in [nil, "qrcode.png"] ->
        case Vlx.VlcRemote.play_file(path) do
          {:ok, _} ->
            # don't care if fails
            if not full? do
              # Process.sleep(500)
              # Vlx.VlcRemote.toggle_fullscreen()
            end

            :ok

          {:error, :disconnected} ->
            :error
        end

      {:ok, %Vlx.VlcStatus{title: title}} ->
        Logger.warn("not displaying IP QR code, file in play: #{inspect(title)}")
        :ignore
    end
  end

  defp find_ip do
    with {:ok, ifs} <- :inet.getifaddrs() do
      Enum.find_value(ifs, fn {_, info} -> find_ip_from_mask(info) end)
    end
  end

  # Trying to find the ip address. Interfaces info come as a keyword list with
  # duplicate :addr and :netmask keys. In my tests each :addr is followed by its
  # :netmask.
  #
  # Here we try to find for an addr that is 4-tuple (ipv4) followed by a {255,
  # 255, 255, 0} netmask which is the common case. For instance docker network
  # have {255, 255, 0, 0}.
  #
  # Obviously this is totally bad and almost random.

  defp find_ip_from_mask([{:addr, {_, _, _, _} = ip}, {:netmask, {255, 255, 255, 0}} | _]) do
    ip
  end

  defp find_ip_from_mask([_ | tail]) do
    find_ip_from_mask(tail)
  end

  defp find_ip_from_mask([]) do
    nil
  end
end
