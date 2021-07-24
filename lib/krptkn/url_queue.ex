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

  @doc """
  Checks the state of the framework.

  Returns `:running` or `:stopped`.

  ## Examples

      iex> Krptkn.UrlQueue.state()
      :running

  """
  def state do
    GenServer.call(__MODULE__, :state)
  end

  @doc """
  Removes all elements from the url queue.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.UrlQueue.clear_queue()
      :ok

  """
  def clear_queue do
    GenServer.cast(__MODULE__, :clear_queue)
  end

  @doc """
  Removes all elements from the ETS table that
  holds the already visited URLs.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.UrlQueue.clear_visited()
      :ok

  """
  def clear_visited do
    :ets.delete_all_objects(@visited_links)
  end

  @doc """
  Resumes the URL queue if it was paused.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.UrlQueue.resume()
      :ok

  """
  def resume do
    GenServer.cast(__MODULE__, :resume)
  end

  @doc """
  Pauses the URL queue so it will stop serving new URLs.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.UrlQueue.pause()
      :ok

  """
  def pause do
    GenServer.cast(__MODULE__, :pause)
  end

  @doc """
  Pushes a URL to the queue and saves it on the ETS table (to
  avoid visiting twice a URL).

  Returns `:ok`.

  ## Examples

      iex> Krptkn.UrlQueue.push("https://stallman.org/")
      :ok

  """
  def push(url) do
    if not found?(url) do
      :ets.insert(@visited_links, {url, NaiveDateTime.utc_now()})
      GenServer.cast(__MODULE__, {:push, url})
    end
  end

  @doc """
  Pops a URL from the queue.

  Returns a string with a URL.

  ## Examples

      iex> Krptkn.UrlQueue.pop()
      "https://stallman.org/"

  """
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

    state_update()

    {:ok, {q, :running}}
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

  # Automatic stuff
  defp state_update do
    Process.send_after(self(), :state_update, 2_000)
  end

  @impl true
  def handle_info(:state_update, {queue, state}) do
    actual_state = if state == :running and :queue.is_empty(queue) do
      :stopped
    else
      state
    end

    KrptknWeb.Endpoint.broadcast!("live_updates:lobby", "state", %{
      state: actual_state
    })

    state_update()

    {:noreply, {queue, state}}
  end
end
