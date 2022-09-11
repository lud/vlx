defmodule Vlx.MediaLib do
  @moduledoc """
  This module helps working with medium files.
  """

  defmodule MFile do
    @enforce_keys [:path, :name, :ext]
    defstruct @enforce_keys
  end

  defmodule MDir do
    @enforce_keys [:path, :name, :children]
    defstruct @enforce_keys
  end

  def read_dir_tree(dir) do
    read_dir_tree(dir, [], dir)
  end

  def read_dir_tree(dir, acc, prefix) do
    Enum.map(File.ls!(dir), fn name ->
      path = Path.join(prefix, name)

      if File.dir?(path) do
        %MDir{name: name, path: path, children: read_dir_tree(path, acc, path)}
      else
        %MFile{name: name, path: path, ext: extension_of(path)}
      end
    end)
  end

  defp extension_of(path) do
    case Path.extname(path) do
      "." <> ext -> ext
      ext -> ext
    end
  end

  def keep_exts(list, exts) when is_list(list) do
    list
    |> Enum.map(fn
      # %MDir{} = d -> d
      %MDir{children: children} = d -> %MDir{d | children: keep_exts(children, exts)}
      %MFile{} = f -> f
    end)
    |> Enum.filter(fn
      %MFile{ext: ext} -> ext in exts
      %MDir{children: []} -> false
      %MDir{} -> true
    end)
  end

  def sort_by_name(list) when is_list(list) do
    list
    |> Enum.sort_by(fn %_{name: name} -> name end)
    |> Enum.map(fn
      %MFile{} = f -> f
      %MDir{children: children} = dir -> %MDir{dir | children: sort_by_name(children)}
    end)
  end
end
