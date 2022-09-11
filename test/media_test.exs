defmodule Vlx.MediaTest do
  use ExUnit.Case, async: true

  alias Vlx.MediaLib
  alias Vlx.MediaLib.{MFile, MDir}

  test "reading the media library" do
    assert [
             %MFile{name: "aaa-fake-movie.mkv", ext: "mkv"},
             %MFile{name: "bbb-fake-sound.mp3", ext: "mp3"},
             %MDir{
               name: "sss-some-series",
               children: [
                 %MFile{name: "episode-1.avi", ext: "avi"},
                 %MFile{name: "episode-2.mkv", ext: "mkv"}
               ]
             },
             %MFile{name: "zzz-some-short.mov", ext: "mov"}
           ] =
             "test/fixtures/tree"
             |> Vlx.MediaLib.read_dir_tree()
             |> Vlx.MediaLib.keep_exts(["mov", "avi", "mkv", "mp3"])
             |> Vlx.MediaLib.sort_by_name()
  end
end
