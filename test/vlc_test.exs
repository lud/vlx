defmodule Vlx.VLCComTest do
  use ExUnit.Case, async: false

  alias Vlx.VLCCom

  test "connecting to VLC" do
    assert {:ok, com} = VLCCom.connect(%{port: 5555, password: "dev"})

    assert :ok ==
             VLCCom.play(
               com,
               "/home/lud/torrent/media/Spider-Man.No.Way.Home.2021.MULTi.720p.BluRay.x265-SceneGuardians.mkv"
             )

    assert [
             %{id: -1, label: "Désactiver", selected: false},
             %{id: 1, label: "VO AC3 5.1 - [Anglais]", selected: true},
             %{id: 2, label: "VF AC3 5.1 - [Français]", selected: false}
           ] = VLCCom.list_audio_tracks(com)

    assert [
             %{id: -1, label: "Désactiver", selected: false},
             %{id: 3, label: "Piste 1 - [Anglais]", selected: false},
             %{id: 4, label: "SDH - [Anglais]", selected: false},
             %{id: 5, label: "FRENCH FULL - [Français]", selected: true},
             %{id: 6, label: "FRENCH FORCED - [Norvégien]", selected: false}
           ] = VLCCom.list_subs_tracks(com)
  end
end
