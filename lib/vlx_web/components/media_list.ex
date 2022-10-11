defmodule VlxWeb.Components.MediaList do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Vlx.MediaLib.{MFile, MDir}
  alias VlxWeb.Components.Text

  def index(assigns) do
    case assigns.media do
      [] ->
        ~H"""
        <div>
          <Text.page_header title="Media" />
          No media found
        </div>
        """

      list ->
        flat = flatten_list(list)

        # <%= render_list_recursive(%{media: list}) %>
        ~H"""
        <div>
          <Text.page_header title="Media" />
          <%= render_list_flat(%{media: flat}) %>
        </div>
        """
    end
  end

  defp flatten_list(list) do
    groups =
      list
      # collect each file in a tuple with {file, dirs} where dirs is all the
      # parent dir names, reversed
      |> collect_by_dir([], [])
      # group by the reversed list of parent dirs
      |> Enum.group_by(fn {_, dirs} -> dirs end)
      # reverse the dir names, and unwrap the files
      # from their {file, dirs} tuple
      |> Enum.map(fn {dirs, files} ->
        dirs = :lists.reverse(dirs)
        files = Enum.map(files, &elem(&1, 0))
        {dirs, files}
      end)
      # replace the dir names lists with a well known tuple
      # and reverse the files since they were initially sorted
      |> Enum.map(fn
        {[], files} -> [{:dir_header, ["/"]}, :lists.reverse(files)]
        {dirs, files} -> [{:dir_header, dirs}, :lists.reverse(files)]
      end)
      |> :lists.flatten()
  end

  defp collect_by_dir(list, dirs \\ [], topacc \\ []) do
    Enum.reduce(list, topacc, fn
      %MFile{} = file, acc ->
        [{file, dirs} | acc]

      %MDir{children: children, name: name} = dir, acc ->
        collect_by_dir(children, [name | dirs], acc)
    end)
  end

  defp render_list_recursive(assigns) do
    ~H"""
    <ul class="break-all">
    <%= for item <- @media do %>
      <%= case item do %>
      <% %MFile{name: name, path: path} -> %>
          <li class="pl-4 cursor-pointer" phx-click={JS.push("play", value: %{path: path})}>
            <span class="media-file">▶ <%= name %></span>
          </li>
        <% %MDir{name: name, children: children} -> %>
          <li class="pl-4">
            <span class="media-dir">🗀 <%= name %></span>
            <%= render_list_recursive(%{media: children}) %>
          </li>
      <% end %>
    <% end %>
    </ul>
    """
  end

  defp render_list_flat(assigns) do
    ~H"""
    <ul class="break-all">
    <%= for item <- @media do %>
      <%= case item do %>
      <% %MFile{name: name, path: path} -> %>
          <li class="cursor-pointer" phx-click={JS.push("play", value: %{path: path})}>
            <span class="media-file">▶ <%= name %></span>
          </li>
        <% {:dir_header, dirs} -> %>
          <li class="mt-2">
            <span class="media-dir">🗀 <%= Enum.intersperse(dirs, " / ") %></span>
          </li>
      <% end %>
    <% end %>
    </ul>
    """
  end
end
