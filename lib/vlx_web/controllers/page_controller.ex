defmodule VlxWeb.PageController do
  use VlxWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
