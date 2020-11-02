defmodule Krptkn.Db do
  @moduledoc """
  This module abstracts database functions. 

  The state is a tuple that contains two lists, one with metadata and one with URLs.
  """

  @min_url_count 50
  @min_metadata_count 10

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, {[], []}, name: __MODULE__)
  end

  def insert_metadata(url, type, metadata) do
    :ok = GenServer.call(__MODULE__, {:insert_metadata, {url, type, metadata}})
  end

  def insert_url(url) do
    :ok = GenServer.call(__MODULE__, {:insert_url, url})
  end
  
  defp insert_batch_url(urls) do
    query = "INSERT INTO visited_urls (session, url) VALUES "

    {_, query_str} = Enum.reduce(urls, {1, ""}, fn _url, {num, str} -> {num+2, str <> "($#{num}, $#{num+1}), "} end)
    query_str = String.trim_trailing(query_str, ", ")
    
    session = Application.get_env(:krptkn, Krptkn.Application)[:session_name]
    query_data = Enum.reduce(urls, [], fn u, acc -> [session, u] ++ acc end)

    Postgrex.query!(:psql, query <> query_str, query_data)
  end

  defp insert_batch_metadata(metadata) do
    query = "INSERT INTO metadata (session, url, type, metadata) VALUES "

    {_, query_str} = Enum.reduce(metadata, {1, ""}, fn _url, {num, str} -> {num+4, str <> "($#{num}, $#{num+1}, $#{num+2}, $#{num+3}), "} end)
    query_str = String.trim_trailing(query_str, ", ")
    
    session = Application.get_env(:krptkn, Krptkn.Application)[:session_name]
    query_data = Enum.reduce(metadata, [], fn {url, type, metadata}, acc -> [session, url, type, metadata] ++ acc end)

    Postgrex.query!(:psql, query <> query_str, query_data)
  end

  defp scheduled_insert do
    Process.send_after(self(), :insert_all, 10_000)
  end

  @impl true
  def init(state) do
    scheduled_insert()

    {:ok, state}
  end

  @impl true
  def handle_call({:insert_url, url}, _from, state) do
    {metadata_queue, url_queue} = state

    count = Enum.count(url_queue)
    if count > @min_url_count do
      insert_batch_url([url | url_queue])
      {:reply, :ok, {metadata_queue, []}}
    else
      {:reply, :ok, {metadata_queue, [url | url_queue]}}
    end
  end

  @impl true
  def handle_call({:insert_metadata, metadata}, _from, state) do
    {metadata_queue, url_queue} = state

    count = Enum.count(metadata_queue)
    if count > @min_metadata_count do
      insert_batch_metadata([metadata | metadata_queue])
      {:reply, :ok, {[], url_queue}}
    else
      {:reply, :ok, {[metadata | metadata_queue], url_queue}}
    end
  end

  @impl true
  def handle_info(:insert_all, state) do
    {metadata_queue, url_queue} = state

    # Insert all data in state
    if url_queue != [] do
      insert_batch_url(url_queue)
    end

    if metadata_queue != [] do
      insert_batch_metadata(metadata_queue)
    end

    # Reschedule once again
    scheduled_insert()

    # Reset the state
    {:noreply, {[], []}}
  end
end