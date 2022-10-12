defmodule Vlx.IpDisplay do
  use GenServer, restart: :temporary

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def stop_qrcode_display do
    GenServer.call(__MODULE__, :stop_qr_display)
  end

  def init(_arg) do
    ip = find_ip()

    port =
      Application.get_env(:vlx, VlxWeb.Endpoint)
      |> Keyword.fetch!(:http)
      |> Keyword.fetch!(:port)

    case find_ip do
      nil ->
        {:stop, :no_ip_found}

      {a, b, c, d} ->
        send(self(), :refresh)
        {:ok, %{url: "http://#{a}.#{b}.#{c}.#{d}:#{port}", keep_qr_display: true}}
    end
  end

  def handle_info(:refresh, %{url: url, keep_qr_display: keep?} = state) do
    # VLC keeps images for 10 seconds. We will re-add the qr-code every 9
    # seconds
    if keep? do
      Process.send_after(self(), :refresh, 9_000)
      display_url(url)
    end

    {:noreply, state}
  end

  def handle_call(:stop_qr_display, _, state) do
    {:reply, :ok, %{state | keep_qr_display: false}}
  end

  defp display_url(url) do
    qrcode =
      url
      |> EQRCode.encode()
      |> EQRCode.png()

    path = :code.priv_dir(:vlx) |> Path.join("qrcode.png")

    File.write!(path, qrcode)

    Vlx.VlcRemote.play_file(path)
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
