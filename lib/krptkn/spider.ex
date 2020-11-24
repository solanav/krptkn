defmodule Krptkn.Spider do
  @moduledoc """
  This module is the producer that extracts the HTML from a given URL.
  The URLs are popped from a global queue defined in UrlQueue.
  """

  require Logger

  use GenStage, restart: :transient

  def start_link(name) do
    Krptkn.Api.register_process(__MODULE__, name, self())
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

  defp change_redirect_url(url, res) do
    uri = URI.parse(url)

    new_path = Enum.reduce(res.headers, "", fn {header, content}, acc ->
      if header == "Location" do
        if String.starts_with?(content, "/") do
          content
        else
          uri.path <> content
        end
      else
        acc
      end
    end)

    URI.to_string(%{uri | path: new_path})
  end

  defp get_type(%HTTPoison.Response{} = res) do
    Enum.reduce(res.headers, :error, fn
      {"Content-Type", type}, _ -> type
      _header, acc -> acc
    end)
  end

  defp request(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 302} = res} ->
        url = change_redirect_url(url, res)
        request(url)
      res -> res
    end
  end

  def handle_demand(demand, {name, count}) when demand > 0 do
    # Sacamos una URL de la queue
    res = case pop_timeout() do
      {:ok, url} ->
        # Hacemos la peticion y sacamos el HTML
        case request(url) do
          {:ok, %HTTPoison.Response{} = res} ->
            type = get_type(res)

            Logger.info("#{name} | #{url}")
            Krptkn.Api.add(:url)
            Krptkn.Api.add_file_type(type)

            {:ok, type, url, res.body}
          {:error, _} -> :error
        end
      {:error, _} -> :error
    end

    case res do
      {:ok, type, url, body} -> {:noreply, [{type, url, body}], {name, count}}
      :error -> {:noreply, [], {name, count + 1}}
    end
  end
end
