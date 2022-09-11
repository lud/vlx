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
    :ok = TCP.send(socket, pass)

    read(socket, 2)

    :inet.setopts(socket, packet: :line)
    dump_messages(socket)

    # header |> IO.inspect(label: "header")
    # [, ] = :binary.split(header, "\n")
    # {:ok, re} = TCP.recv(socket, 0, 5000)
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

  defp dump_messages(socket) do
    readline(socket)
    dump_messages(socket)
  end
end
