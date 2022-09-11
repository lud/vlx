defmodule Vlx.VLCCom do
  @moduledoc """
  This module controls VLC with a TCP connexion.
  """

  alias :gen_tcp, as: TCP

  defp config do
    config = Map.new(Application.fetch_env!(:vlx, :vlc))
  end

  def connect do
    connect(config())
  end

  def connect(%{port: port, password: pass}) do
    {:ok, socket} = TCP.connect({127, 0, 0, 1}, port, [:binary, active: false])

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

    {:ok, socket}
  end

  defp command(socket, com) when is_binary(com) do
    :ok = consume_prompt(socket)
    :ok = TCP.send(socket, com <> "\n")
  end

  defp consume_prompt(socket) do
    :inet.setopts(socket, packet: :raw)
    "> " = read(socket, 2)
    :inet.setopts(socket, packet: :line)
  end

  defp command(socket, commands) when is_list(commands) do
    Enum.each(commands, fn c -> command(socket, c) end)
  end

  defp readline(socket) do
    {:ok, line} = TCP.recv(socket, 0, 50000)
    IO.inspect(line, label: "tcp")
    line
  end

  defp read(socket, len) do
    {:ok, raw} = TCP.recv(socket, len, 50000)
    IO.inspect(raw, label: "tcp")
    raw
  end

  def play(socket, file) do
    command(socket, ["stop", "clear", "add #{file}", "play"])
  end

  def list_audio_tracks(socket) do
    command(socket, "atrack")

    socket
    |> collect_list()
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
    items = collect_list_items(socket, [])
    items |> IO.inspect(label: "items")
  end

  defp collect_list_items(socket, acc) do
    case readline(socket) do
      "+----" <> _ -> :lists.reverse(acc)
      "| " <> item -> collect_list_items(socket, [item | acc])
    end
  end
end
