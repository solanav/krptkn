defmodule KrptknWeb.PageController do
  use KrptknWeb, :controller

  def new(conn, params) do
    IO.inspect(params)

    Process.sleep(100_000)

    redirect(conn, to: "/info")
  end

  def index(conn, params) do
    IO.inspect(params)

    render(conn, "index.html")
  end
end
