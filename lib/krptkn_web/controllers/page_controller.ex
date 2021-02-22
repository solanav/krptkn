defmodule KrptknWeb.PageController do
  use KrptknWeb, :controller

  def new(conn, %{"starting_url" => url}) do
    Krptkn.UrlQueue.push(url)

    render(conn, "index.html")
  end

  def new(conn, %{"action" => "pause"}) do
    Krptkn.UrlQueue.pause()

    render(conn, "index.html")
  end

  def new(conn, %{"action" => "resume"}) do
    Krptkn.UrlQueue.resume()

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
    Krptkn.Repo.delete_all(Krptkn.Metadata)
    Krptkn.Repo.delete_all(Krptkn.Url)

    render(conn, "index.html")
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
