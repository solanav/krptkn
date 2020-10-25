defmodule Krptkn.UrlQueue do
  @moduledoc """
  This module defines a GenServer that acts as a global queue so that consumers
  can push new URLs that they find and producers can pop them to extract the HTML.
  """

  use GenServer

  @visited_links :visited_links

  def start_link(initial_url) do
    GenServer.start_link(__MODULE__, initial_url, name: __MODULE__)
  end

  def push(element) do
    if :ets.lookup(@visited_links, element) == [] do
      :ets.insert(@visited_links, {element, NaiveDateTime.utc_now()})
      GenServer.cast(__MODULE__, {:push, element})
    end
  end

  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  @impl true
  def init(initial_url) when is_binary(initial_url) do
    # Start an ets for saving visited links
    :ets.new(@visited_links, [:set, :public, :named_table])

    q = :queue.new()
    {:ok, :queue.in(initial_url, q)}
  end

  @impl true
  def handle_call(:pop, _from, queue) do
    case :queue.out(queue) do
      {:empty, q} -> {:reply, {:error, []}, q}
      {{:value, value}, q} -> {:reply, {:ok, value}, q}
    end
  end

  @impl true
  def handle_cast({:push, element}, queue) do
    {:noreply, :queue.in(element, queue)}
  end
end
