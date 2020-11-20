defmodule KrptknWeb.Info do
  use KrptknWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def url_count do
    Krptkn.Api.count(:url) |> inspect()
  end

  def memory(type) do
    i = case type do
      :total -> 0
      :processes -> 1
      :system -> 3
      :atom -> 4
      :binary -> 6
      :code -> 7
      :ets -> 8
    end

    Krptkn.Api.memory
    |> Enum.map(fn l ->
      val = Enum.at(l, i)
      |> elem(1)

      val / 1_000_000
    end)
    |> Enum.take(30)
    |> inspect(limit: :infinity)
  end
end
