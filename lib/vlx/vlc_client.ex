defmodule Vlx.VlcClient do
  @moduledoc """
  Simple HTTP client for the VLC Lua Http endpoint.
  """

  require Logger
  alias __MODULE__, as: C

  @enforce_keys [:host, :port, :password]
  defstruct @enforce_keys

  def new(opts) do
    struct!(__MODULE__, opts)
  end

  defp build_req(client, url) when is_binary(url) do
    build_req(client, url: url)
  end

  defp build_req(%C{host: host, port: port, password: password}, opts)
       when is_list(opts) do
    Req.new([base_url: "http://#{host}:#{port}", auth: {"", password}] ++ opts)
  end

  defp log_get(request) do
    Logger.debug("#{request.method} #{request.options.base_url}#{request.url}")
    Req.get(request)
  end

  defp ok_json({:ok, %Req.Response{} = resp}) do
    ok_json(resp)
  end

  defp ok_json({:error, _} = err) do
    err
  end

  defp ok_json(%Req.Response{status: 200, body: body}) do
    Jason.decode(body)
  end

  defp ok_json(%Req.Response{status: 404}) do
    {:error, "invalid url – 404 Not Found"}
  end

  defp get_json(client, path) do
    client |> build_req(path) |> log_get() |> ok_json()
  end

  defp get_json(client, path, query_params) do
    path = path <> "?" <> URI.encode_query(query_params)
    client |> build_req(path) |> log_get() |> ok_json()
  end

  def connected?(client) do
    case get_status(client) do
      {:ok, _} -> true
      _ -> false
    end
  end

  def get_streams(%C{} = client, type \\ :all) do
    with {:ok, status} <- get_status(client) do
      Vlx.VlcStatus.get_streams(status, type)
    end
  end

  def get_status(%C{} = client) do
    get_json(client, "/requests/status.json")
  end

  def play_file(client, path) do
    path = convert_path(path)

    get_json(client, "/requests/status.json", command: :in_play, input: path)
  end

  defp convert_path(path) do
    case :os.type() do
      {:win32, _} -> String.replace(path, "/", "\\")
      _ -> path
    end
  end

  def set_subtitle_track(client, :disable) do
    set_subtitle_track(client, -1)
  end

  def set_subtitle_track(client, id) when is_integer(id) do
    get_json(client, "/requests/status.json", command: :subtitle_track, val: id)
  end

  def set_audio_track(client, :disable) do
    set_audio_track(client, -1)
  end

  def set_audio_track(client, id) when is_integer(id) do
    get_json(client, "/requests/status.json", command: :audio_track, val: id)
  end

  def resume_playback(client) do
    get_json(client, "/requests/status.json", command: :pl_forceresume)
  end

  def pause_playback(client) do
    get_json(client, "/requests/status.json", command: :pl_forcepause)
  end

  def relative_seek(client, seconds) when is_integer(seconds) do
    val =
      case seconds do
        n when n > 0 -> "+#{seconds}s"
        n -> "#{seconds}s"
      end

    get_json(client, "/requests/status.json", command: :seek, val: val)
  end

  def empty_playlist(client) do
    get_json(client, "/requests/status.json", command: :pl_empty)
  end
end
