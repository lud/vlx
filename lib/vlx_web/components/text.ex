defmodule VlxWeb.Components.Text do
  use Phoenix.Component
  alias VlxWeb.Components.Icons

  attr :title, :string, required: true
  attr :smalltop, :string, required: false
  attr :break, :boolean, default: false

  def page_header(assigns) do
    assigns =
      assigns
      |> Map.put_new(:smalltop, nil)
      |> Map.put_new(:break, false)

    ~H"""
    <%= if @smalltop do %>
      <span class="text-sm"><%=@smalltop%></span>
      <br/>
    <% end %>
    <h2 class={"text-xl font-bold mb-4 #{if(@break, do: "break-all")}"}>
      <%= @title %>
    </h2>
    """
  end

  attr :icon, :string, default: nil
  attr :title, :string, required: true

  def section_header(assigns) do
    ~H"""
    <h3 class="flex flex-row items-center text-lg font-bold mb-2 mt-4">
      <%= if @icon do %>
         <Icons.large icon={@icon} class="mr-2" />
      <% end %>
      <%= @title %>
    </h3>
    """
  end
end
