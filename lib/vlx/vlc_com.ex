defmodule Vlx.VLCCom do
  @moduledoc """
  This module controls VLC with a TCP connexion.
  """

  require Logger

  alias :gen_tcp, as: TCP

  def connect(%{port: port, password: pass}, timeout \\ 5000) do
    {:ok, socket} = TCP.connect({127, 0, 0, 1}, port, [:binary, active: false], timeout)

    handshake(socket, pass)
  end

  defp handshake(socket, pass) do
    # Receive the header
    :inet.setopts(socket, packet: :line)
    "VLC media player 3" <> _ = readline(socket)

    :inet.setopts(socket, packet: :raw)
    prompt = "Password: " <> <<255, 251, 1>>
    "Password: " <> <<255, 251, 1>> = read(socket, byte_size(prompt))
    :ok = TCP.send(socket, pass <> "\n")

    :inet.setopts(socket, packet: :line)

    <<255, 252, 1, 13, 10>> = readline(socket)
    "Welcome, Master" <> _ = readline(socket)

    Logger.info("vlc handshake complete")

    {:ok, socket}
  end

  defp command(socket, com) when is_binary(com) do
    Process.sleep(500)
    :ok = consume_prompt(socket)
    Logger.debug("[tcp send] #{inspect(com)}")
    :ok = TCP.send(socket, com <> "\n")
  end

  defp command(socket, commands) when is_list(commands) do
    Enum.each(commands, fn c -> command(socket, c) end)
  end

  defp consume_prompt(socket) do
    :inet.setopts(socket, packet: :raw)
    "> " = read(socket, 2)
    :inet.setopts(socket, packet: :line)
  end

  defp readline(socket) do
    {:ok, line} = TCP.recv(socket, 0, 5000)
    Logger.debug("[tcp line] #{inspect(line)}")
    line
  end

  defp read(socket, len) do
    {:ok, raw} = TCP.recv(socket, len, 5000)
    Logger.debug("[tcp raw] #{inspect(raw)}")
    raw
  end

  @platform (case(:os.type()) do
               {:win32, _} -> :win
               _ -> :other
             end)

  def play(socket, file) do
    file =
      case @platform do
        :win -> String.replace(file, "/", "\\")
        _ -> file
      end

    command(socket, ["stop", "clear", "add #{file}", "play"])
    await_playback(socket)
  end

  def atrack(socket, id) do
    command(socket, "atrack #{id}")
  end

  def strack(socket, id) do
    command(socket, "strack #{id}")
  end

  def await_playback(socket) do
    Process.sleep(500)
    command(socket, "get_title")

    case readline(socket) do
      "" -> await_playback(socket)
      b when is_binary(b) -> :ok
    end
  end

  def get_title(socket) do
    command(socket, "get_title")
    readline(socket) |> String.trim()
  end

  def list_audio_tracks(socket) do
    command(socket, "atrack")
    socket |> collect_list() |> parse_list()
  end

  def list_subs_tracks(socket) do
    command(socket, "strack")
    socket |> collect_list() |> parse_list()
  end

  defp parse_list(items) do
    items
    |> Enum.map(fn item ->
      [id, label] = item |> String.trim() |> String.split(" - ", parts: 2)
      id = String.to_integer(id)
      selected = String.ends_with?(label, "*")
      label = String.trim_trailing(label, " *")
      %{id: id, selected: selected, label: label}
    end)
    |> Enum.sort_by(fn m -> m.id end)
  end

  defp collect_list(socket) do
    "+----" <> _ = readline(socket)
    collect_list_items(socket, [])
  end

  defp collect_list_items(socket, acc) do
    case readline(socket) do
      "| " <> item -> collect_list_items(socket, [item | acc])
      "+----" <> _ -> :lists.reverse(acc)
    end
  end
end
