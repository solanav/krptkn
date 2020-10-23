defmodule Krptkn.Spider do
  require Logger

  use GenStage

  def start_link(name) do
    GenStage.start_link(__MODULE__, name, name: name)
  end

  def init(name) do
    {:producer, {name, 0}}
  end

  def handle_demand(demand, {name, count}) when demand > 0 do
    events = Enum.map(0..demand, fn _ ->
      # Sacamos una URL de la queue
      case Krptkn.UrlQueue.pop() do
        {:ok, url} ->
          Logger.info("#{name} | #{url}")
          # Hacemos la peticion y sacamos el HTML
          case HTTPoison.get(url) do
            {:ok, %HTTPoison.Response{body: body}} ->
              Logger.info("Get ok")
              {:ok, url, body}
            {:error, _} ->
              Logger.error("Get error")
              {:error, "", ""}
          end
        {:error, []} ->
          Logger.error("Pop error")
          Process.sleep(5_000)
          {:error, "", ""}
      end
    end)
    # Filter out the errors
    |> Enum.filter(fn
      {:ok, _, _} -> true
      {:error, _, _} -> false
    end)
    # Remove the result atom
    |> Enum.map(fn {:ok, url, html} -> {url, html} end)

    {:noreply, events, {name, count + 1}}
  end
end
