defmodule Vlx.VlcStatus do
  @moduledoc """
  Extracts informations from VLC status payloads.
  """

  def get_streams(status, type \\ :all) do
    case pull_streams(status) do
      {:ok, streams} -> {:ok, refine_streams(streams, type)}
      {:error, _} = err -> err
    end
  end

  def get_filename(status) do
    case pull_streams(status) do
      {:ok, %{"meta" => %{"filename" => filename}}} -> {:ok, filename}
      {:ok, _} -> {:ok, "No File"}
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
end
