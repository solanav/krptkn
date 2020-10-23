defmodule Krptkn.Spider do
  require Logger

  use GenStage, restart: :transient

  def start_link(name) do
    GenStage.start_link(__MODULE__, name, name: name)
  end

  def init(name) do
    {:producer, {name, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  defp pop_timeout do
    url = Enum.reduce_while(0..50, "", fn
      50, "" -> {:halt, ""}
      _, "" ->
        case Krptkn.UrlQueue.pop() do
          {:ok, url} -> {:halt, url}
          {:error, _} ->
            Process.sleep(100)
            {:cont, ""}
        end
    end)

    case url do
      "" -> {:error, []}
      url -> {:ok, url}
    end
  end

  defp get_type(%HTTPoison.Response{} = res) do
    Enum.reduce(res.headers, :error, fn
      {"Content-Type", type}, _ -> type
      _header, acc -> acc
    end)
  end

  def handle_demand(demand, {name, count}) when demand > 0 do
    # Sacamos una URL de la queue
    res = case pop_timeout() do
      {:ok, url} ->
        Logger.info("Pop ok | #{name} | #{url}")
        # Hacemos la peticion y sacamos el HTML
        case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{} = res} ->
            {:ok,  get_type(res), url, res.body}
          {:error, _} ->
            :error
        end
      {:error, _} ->
        Logger.error("Pop failed | #{name}")
        :error
    end

    case res do
      {:ok, type, url, body} -> {:noreply, [{type, url, body}], {name, count}}
      :error -> {:noreply, [], {name, count + 1}}
    end
  end
end
