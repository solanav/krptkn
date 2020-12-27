defmodule KrptknWeb.PageController do
  use KrptknWeb, :controller

  def new(conn, %{"starting_url" => url}) do
    Krptkn.UrlQueue.push(url)

    render(conn, "index.html")
  end

  def index(conn, params) do
    IO.inspect(params)

    render(conn, "index.html")
  end
end
