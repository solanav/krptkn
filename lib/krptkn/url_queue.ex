defmodule Krptkn.UrlQueue do
  @moduledoc """
  This module defines a GenServer that acts as a global queue so that consumers
  can push new URLs that they find and producers can pop them to extract the HTML.
  """

  use GenServer

  @visited_links :visited_links

  def start_link(initial_urls) do
    GenServer.start_link(__MODULE__, initial_urls, name: __MODULE__)
  end

  # Admin utils

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def clear_queue do
    GenServer.cast(__MODULE__, :clear_queue)
  end

  def clear_visited do
    :ets.delete_all_objects(@visited_links)
  end

  def resume do
    GenServer.cast(__MODULE__, :resume)
  end

  def pause do
    GenServer.cast(__MODULE__, :pause)
  end

  # Queue utils

  def push(url) do
    if not found?(url) do
      :ets.insert(@visited_links, {url, NaiveDateTime.utc_now()})
      GenServer.cast(__MODULE__, {:push, url})
    end
  end

  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  defp found?(url), do: :ets.lookup(@visited_links, url) != []

  @impl true
  def init(initial_urls) when is_list(initial_urls) do
    # Start an ets for saving visited links
    :ets.new(@visited_links, [:set, :public, :named_table])

    q = :queue.new()

    # Insert the initial urls
    q = Enum.reduce(initial_urls, q, fn url, q ->
      :queue.in(url, q)
    end)

    {:ok, {q, :running}}
  end

  @impl true
  def handle_call(:state, _from, {queue, state}) do
    if state == :running and :queue.is_empty(queue) do
      {:reply, :stopped, {queue, state}}
    else
      {:reply, state, {queue, state}}
    end
  end

  @impl true
  def handle_call(:pop, _from, {queue, :paused}) do
    {:reply, {:error, []}, {queue, :paused}}
  end

  @impl true
  def handle_call(:pop, _from, {queue, :running}) do
    case :queue.out(queue) do
      {:empty, q} -> {:reply, {:error, []}, {q, :running}}
      {{:value, value}, q} -> {:reply, {:ok, value}, {q, :running}}
    end
  end

  @impl true
  def handle_cast({:push, url}, {queue, state}) do
    {:noreply, {:queue.in(url, queue), state}}
  end

  @impl true
  def handle_cast(:resume, {queue, _old_state}) do
    {:noreply, {queue, :running}}
  end

  @impl true
  def handle_cast(:pause, {queue, _old_state}) do
    {:noreply, {queue, :paused}}
  end

  @impl true
  def handle_cast(:clear_queue, {_old_queue, state}) do
    {:noreply, {:queue.new(), state}}
  end
end
