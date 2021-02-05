defmodule KrptknWeb.PageController do
  use KrptknWeb, :controller

  def new(conn, %{"starting_url" => url}) do
    Krptkn.UrlQueue.push(url)

    render(conn, "index.html")
  end

  def new(conn, %{"action" => "pause"}) do
    IO.inspect("This button does nothing yet")
    IO.inspect("This button does nothing yet")
    IO.inspect("This button does nothing yet")
    IO.inspect("This button does nothing yet")

    render(conn, "index.html")
  end

  def new(conn, %{"action" => "stop"}) do
    Krptkn.UrlQueue.clear_queue()

    render(conn, "index.html")
  end

  def new(conn, %{"action" => "clearram"}) do
    Krptkn.UrlQueue.clear_queue()
    Krptkn.UrlQueue.clear_visited()
    Krptkn.Api.delete_all()

    render(conn, "index.html")
  end

  def new(conn, %{"action" => "cleardb"}) do
    IO.inspect("This button does nothing yet")
    IO.inspect("This button does nothing yet")
    IO.inspect("This button does nothing yet")
    IO.inspect("This button does nothing yet")

    render(conn, "index.html")
  end

  def index(conn, params) do
    render(conn, "index.html")
  end
end
