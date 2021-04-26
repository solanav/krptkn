defmodule KrptknWeb.StateController do
  use KrptknWeb, :controller

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

    Krptkn.Api.memory()
    |> Enum.map(fn l ->
      val = Enum.at(l, i)
      |> elem(1)

      val / 1_000_000
    end)
    |> Enum.take(30)
    |> Enum.reverse()
  end

  def index(conn, %{"param" => "processes"}) do
    json(conn, Krptkn.Api.processes())
  end

  def index(conn, %{"param" => "scheduler"}) do
    data = Enum.reduce(Krptkn.Api.scheduler(), %{}, fn frame, acc ->
      frame = frame
      |> List.delete_at(0)
      |> List.delete_at(0)

      Enum.reduce(frame, acc, fn {tag, id, _util, perc}, acc2 ->
        {f, _} = Float.parse(List.to_string(List.delete_at(perc, length(perc) - 1)))
        name = "#{Atom.to_string(tag)}#{id}"

        case Map.fetch(acc2, name) do
          {:ok, val} -> Map.put(acc2, name, [f | val])
          :error -> Map.put(acc2, name, [f])
        end
      end)
    end)

    json(conn, data)
  end

  def index(conn, %{"param" => "count", "type" => type}) do
    json(conn, Krptkn.Api.count(String.to_atom(type)))
  end

  def index(conn, %{"param" => "count_history", "type" => type}) do
    json(conn, Krptkn.Api.count_history(String.to_atom(type)))
  end

  def index(conn, %{"param" => "memory", "type" => type}) do
    json(conn, memory(String.to_atom(type)))
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
