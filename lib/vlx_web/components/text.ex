defmodule VlxWeb.Components.Text do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def section_header(assigns) do
    ~H"""
    <h2 class="text-xl"><%= @title %></h2>
    """
  end

  def sub_header(assigns) do
    ~H"""
    <h3 class="text-lg"><%= @title %></h3>
    """
  end
end
