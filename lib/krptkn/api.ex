defmodule Krptkn.Api do
  @moduledoc """
  This "API" allows to save meta information about Krptkn's state
  and exposes functions so phoenix can get the information and display it.
  """

  require Logger

  use GenServer

  @spec start_link([]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Deletes all data saved on this module (URLs and the database remain intact).

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.delete_all()
      :ok

  """
  def delete_all do
    GenServer.cast(__MODULE__, :clear)
  end

  @doc """
  Adds one to a count.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.add(:metadata)
      :ok

  """
  @spec add(:url | :danger | :metadata | :fmetadata) :: any
  def add(type) do
    type = String.to_atom("#{Atom.to_string(type)}_count")
    GenServer.cast(__MODULE__, {:add, type})
  end

  @doc """
  Gets the count of an element.

  Returns a number.

  ## Examples

      iex> Krptkn.Api.count(:metadata)
      132

  """
  @spec count(:url | :danger | :metadata | :fmetadata) :: any
  def count(type) do
    type = String.to_atom("#{Atom.to_string(type)}_count")
    GenServer.call(__MODULE__, {:count, type})
  end

  # Metadata

  @doc """
  Adds a piece of metadata and increments the count of metadata.
  There is no need to call Krptkn.Api.add(:metadata) if you call this method.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.add_metadata(%{...})
      :ok

  """
  def add_metadata(metadata) do
    add(:metadata)
    GenServer.cast(__MODULE__, {:add_metadata, metadata})
  end

  @doc """
  Returns the metadata we have saved until now.

  Returns list of maps.

  ## Examples

      iex> Krptkn.Api.metadata()
      [
        %{...},
        %{...},
        %{...}
      ]

  """
  def metadata do
    GenServer.call(__MODULE__, :metadata)
  end

  # Dangerous metadata

  @doc """
  Adds a piece of metadata detected to be dangerous.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.add_dangerous_metadata(%{...})
      :ok

  """
  def add_dangerous_metadata(metadata) do
    GenServer.cast(__MODULE__, {:add_dangerous_metadata, metadata})
  end

  @doc """
  Returns the dangerous metadata we have saved until now.

  Returns list of maps.

  ## Examples

      iex> Krptkn.Api.dangerous_metadata()
      [
        %{...},
        %{...},
        %{...}
      ]

  """
  def dangerous_metadata do
    GenServer.call(__MODULE__, :dangerous_metadata)
  end

  @doc """
  Returns the last URLs that we have visited.

  Returns a list of strings.

  ## Examples

      iex> Krptkn.Api.last_urls()
      [
        %{index: 3, url: "https://hexdocs.pm/elixir/GenServer.html"},
        %{index: 2, url: "https://hexdocs.pm/elixir/Kernel.SpecialForms.html"},
        %{index: 1, url: "https://hexdocs.pm/elixir/Atom.html"},
      ]

  """
  def last_urls do
    GenServer.call(__MODULE__, :last_urls)
  end

  @doc """
  Adds a URL to the last visited URLs list.

  Returns `:ok`.

  ## Examples

      iex> index = Krptkn.Api.count(:url)
      iex> Krptkn.Api.add_last_url(%{
        index: index,
        url: "https://stallman.org/"}
      )
      :ok

  """
  def add_last_url(url) do
    GenServer.cast(__MODULE__, {:add_last_url, url})
  end

  # Init

  @doc "State of the API module. This is all the information being saved."
  def empty_state do
    %{
      url_count: 0,
      danger_count: 0,
      metadata_count: 0,
      fmetadata_count: 0,

      last_urls: [],
      metadata: [],
      dangerous_metadata: [],
    }
  end

  @impl true
  def init([]) do
    {:ok, empty_state()}
  end

  # Update state

  @impl true
  def handle_cast(:clear, _old_state) do
    {:noreply, empty_state()}
  end

  @impl true
  def handle_cast({:add_last_url, url}, state) do
    KrptknWeb.Endpoint.broadcast!("live_updates:lobby", "url", %{
      index: state.url_count,
      urls: [url | state.last_urls]
    })

    {:noreply, %{state | last_urls: Enum.slice([url | state.last_urls], 0..10)}}
  end

  @impl true
  def handle_cast({:add_metadata, metadata}, state) do
    KrptknWeb.Endpoint.broadcast!("live_updates:lobby", "metadata", %{
      metadata: [metadata | state.metadata]
    })

    {:noreply, %{state | metadata: [metadata | state.metadata]}}
  end

  @impl true
  def handle_cast({:add_dangerous_metadata, metadata}, state) do
    {:noreply, %{state | dangerous_metadata: [metadata | state.dangerous_metadata]}}
  end

  @impl true
  def handle_cast({:add, type}, state) do
    KrptknWeb.Endpoint.broadcast!("live_updates:lobby", "count", %{
      name: type,
      value: state[type] + 1
    })

    {:noreply, %{state | type => state[type] + 1}}
  end

  # Retreive state
  @impl true
  def handle_call(:last_urls, _from, state) do
    {:reply, state.last_urls, state}
  end

  @impl true
  def handle_call(:processes, _from, state) do
    {:reply, state.processes, state}
  end

  @impl true
  def handle_call(:metadata, _from, state) do
    {:reply, state.metadata, state}
  end

  @impl true
  def handle_call(:dangerous_metadata, _from, state) do
    {:reply, state.dangerous_metadata, state}
  end

  @impl true
  def handle_call({:count, type}, _from, state) do
    {:reply, state[type], state}
  end

  @impl true
  def handle_call({:history, type}, _from, state) do
    {:reply, state[type], state}
  end

  @impl true
  def handle_call(:memory, _from, state) do
    {:reply, state.memory, state}
  end

  @impl true
  def handle_call(:scheduler, _from, state) do
    {:reply, state.scheduler, state}
  end

  @impl true
  def handle_call(:reductions, _from, state) do
    {:reply, state.reductions, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error("Supervisor received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
