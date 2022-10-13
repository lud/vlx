defmodule Vlx.VlcStatus do
  @moduledoc """
  Extracts informations from VLC status payloads.
  """

  @enforce_keys [:audio_tracks, :sub_tracks, :title, :state, :fullscreen, :actual]
  defstruct @enforce_keys

  def empty do
    %__MODULE__{
      audio_tracks: [],
      sub_tracks: [],
      title: nil,
      state: "unknown",
      fullscreen: false,
      actual: false
    }
  end

  def from_raw(raw_status) do
    %__MODULE__{
      actual: true,
      audio_tracks: or_empty(get_streams(raw_status, :audio)),
      sub_tracks: or_empty(get_streams(raw_status, :subtitles)),
      title: or_default(get_filename(raw_status), nil),
      fullscreen: as_bool(Map.get(raw_status, "fullscreen", 0)),
      state:
        case raw_status do
          %{"state" => state} -> state
          _ -> "unknown"
        end
    }
  end

  defp get_streams(status, type \\ :all) do
    case pull_streams(status) do
      {:ok, streams} -> {:ok, refine_streams(streams, type)}
      {:error, _} = err -> err
    end
  end

  defp get_filename(status) do
    case pull_streams(status) do
      {:ok, %{"meta" => %{"filename" => filename}}} -> {:ok, filename}
      {:ok, _} -> {:ok, nil}
      {:error, _} = err -> err
    end
  end

  defp pull_streams(status) do
    with {:ok, info} <- Map.fetch(status, "information"),
         {:ok, streams} <- Map.fetch(info, "category") do
      {:ok, streams}
    else
      :error -> {:error, "streams are not defined"}
    end
  end

  defp refine_streams(streams, type) do
    streams
    |> Enum.flat_map(fn
      {"Flux " <> id, %{"Type_" => "Audio"} = stream}
      when type in [:all, :audio] ->
        collect_stream(id, stream)

      {"Flux " <> id, %{"Type_" => "Sous-titres" <> _} = stream}
      when type in [:all, :subtitles] ->
        collect_stream(id, stream)

      _ ->
        []
    end)
    |> Map.new()
  end

  defp collect_stream(id, stream) do
    case Integer.parse(id) do
      {id, ""} -> [{id, stream}]
      _ -> []
    end
  end

  defp or_empty({:ok, list}), do: list
  defp or_empty({:error, _}), do: []
  defp or_default({:ok, v}, _), do: v
  defp or_default({:error, _}, default), do: default

  defp as_bool(1), do: true
  defp as_bool(0), do: false
  defp as_bool(false), do: false
  defp as_bool(true), do: true
end
