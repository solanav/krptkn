defmodule KrptknWeb.StateController do
  use KrptknWeb, :controller

  def index(conn, %{"param" => "count", "type" => type}) do
    json(conn, Krptkn.Api.count(String.to_atom(type)))
  end

  def index(conn, %{"param" => "queue_state"}) do
    json(conn, Krptkn.UrlQueue.state())
  end

  def index(conn, %{"param" => "dangerous_metadata"}) do
    json(conn, Krptkn.Api.dangerous_metadata())
  end

  def index(conn, %{"param" => "last_metadata"}) do
    json(conn, Krptkn.Api.metadata())
  end

  def index(conn, %{"param" => "last_urls"}) do
    last_urls = Enum.map(Krptkn.Api.last_urls(), fn {i, url} ->
      %{
        index: i,
        url: url,
      }
    end)

    json(conn, last_urls)
  end
end
