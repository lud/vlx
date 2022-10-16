defmodule VlxWeb.Components.MediaList do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Vlx.MediaLib.{MFile, MDir}
  alias VlxWeb.Components.Text
  alias VlxWeb.Components.Icons

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
        assigns = assign(assigns, :flat, flatten_list(list))

        ~H"""
        <div>
          <Text.page_header title="Media" />
          <.render_list_flat media={@flat} last_clicked_path={@last_clicked_path} />
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

  defp render_list_flat(assigns) do
    ~H"""
    <ul class="break-all">
    <%= for item <- @media do %>
      <%= case item do %>
      <% %MFile{name: name, path: path} -> %>
          <li class={"flex flex-row p-2 my-1 border border-gray-500 rounded cursor-pointer #{if(@last_clicked_path == path, do: "text-orange-500", else: "")}"} phx-click={JS.push("play", value: %{path: path})}>
            <Icons.large icon="play" class="text-orange-500 dark:text-orange-300"/> <span class="ml-2"><%= name %></span>
          </li>
        <% {:dir_header, dirs} -> %>
          <li class="text-gray-400 mt-8 mb-4 flex flex-row">
            <Icons.large icon="folder" /> <span class="ml-2"><%= Enum.map_intersperse(dirs, " / ",&shorten_name/1) %></span>
          </li>
      <% end %>
    <% end %>
    </ul>
    """
  end

  @allowed_size 30

  defp shorten_name(str) do
    case str do
      # yeah I know UTF-8 is multibyte, but the approximation is fine
      <<_::binary-size(@allowed_size), _::binary>> -> String.slice(str, 0, @allowed_size) <> "…"
      _ -> str
    end
  end
end
