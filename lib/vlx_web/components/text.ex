defmodule VlxWeb.Components.Text do
  use Phoenix.Component

  def page_header(assigns) do
    assigns =
      assigns
      |> Map.put_new(:smalltop, nil)
      |> Map.put_new(:break, false)

    ~H"""
    <h2 class={"text-xl mb-4 #{if(@break, do: "break-all")}"}>
      <%= if @smalltop do %>
         <span class="text-sm"><%=@smalltop%></span>
         <br/>
      <% end %>
      <%= @title %>
    </h2>
    """
  end

  def section_header(assigns) do
    ~H"""
    <h3 class="text-lg mb-2 mt-4"><%= @title %></h3>
    """
  end
end
