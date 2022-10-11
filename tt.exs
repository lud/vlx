alias Vlx.VlcClient

client = VlcClient.new(host: "localhost", port: 8080, password: "dev")

movie =
  "/home/lud/torrent/media/Spider-Man.No.Way.Home.2021.MULTi.720p.BluRay.x265-SceneGuardians.mkv"

VlcClient.empty_playlist(client)
|> IO.inspect(label: "empty_playlist")

VlcClient.play_file(client, movie)
|> IO.inspect(label: "play_file")

# VlcClient.set_subtitle_track(client, 1)
# |> IO.inspect(label: "set_subtitle_track")

# VlcClient.get_streams(client)
# |> IO.inspect(label: "get_streams")

# VlcClient.get_streams(client, :subtitles)
# |> IO.inspect(label: "get_streams :subtitles")

# VlcClient.get_streams(client, :audio)
# |> IO.inspect(label: "get_streams :audio")

# VlcClient.set_audio_track(client, 1)
# |> IO.inspect(label: "set_audio_track")

# VlcClient.resume_playback(client)
# |> IO.inspect(label: "resume_playback")

# VlcClient.pause_playback(client)
# |> IO.inspect(label: "resume_playback")

VlcClient.relative_seek(client, -1)
|> IO.inspect(label: "relative_seek")
