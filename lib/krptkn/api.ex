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
  Adds a process to the list.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.register_process(__MODULE__, name, self())
      :ok

  """
  def register_process(module, name, pid) do
    GenServer.cast(__MODULE__, {:register_process, module, name, pid})
  end

  @doc """
  Returns the list of processes.

  Returns a list of maps.

  ## Examples

      iex> Krptkn.Api.processes()
      [
        %{...},
        %{...},
        %{...}
      ]

  """
  def processes do
    GenServer.call(__MODULE__, :processes)
    |> Enum.map(fn {module, name, pid, state} ->
      id = if name == "" do
        inspect(pid)
      else
        name
      end

      proc_info = Process.info(pid)
      {fun_module, fun_name, fun_arity} = proc_info[:current_function]

      %{
        module: module,
        id: id,
        state: state,
        function: "#{fun_module}.#{Atom.to_string(fun_name)}/#{fun_arity}",
        reductions: proc_info[:reductions],
        heap: proc_info[:heap_size],
        stack: proc_info[:stack_size],
      }
    end)
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

  @spec count_history(:url | :danger | :metadata | :fmetadata) :: any
  @doc """
  Returns history of counts of elements.
  The interval is one second.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.count_history(:metadata)
      [123, 145, 167, 178]

  """
  def count_history(type) do
    type = String.to_atom("#{Atom.to_string(type)}_history")
    GenServer.call(__MODULE__, {:history, type}) |> Enum.reverse()
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
  Returns the scheduler state. To see the structure of the data, this is how it is saved:
  `:scheduler.utilization(:scheduler.sample_all())`
  """
  def scheduler do
    GenServer.call(__MODULE__, :scheduler)
  end

  @doc """
  Adds a file type to the list.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.add_file_type(file_type)
      :ok

  """
  def add_file_type(file_type) do
    GenServer.cast(__MODULE__, {:add_file_type, file_type})
  end

  @doc """
  Adds a response type to the list.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.add_response_type(response_type)
      :ok

  """
  def add_response_type(response_type) do
    GenServer.cast(__MODULE__, {:add_response, response_type})
  end

  @doc """
  Returns the last URLs that we have visited.

  Returns a list of strings.

  ## Examples

      iex> Krptkn.Api.last_urls()
      [
        "https://hexdocs.pm/elixir/GenServer.html",
        "https://hexdocs.pm/elixir/Kernel.SpecialForms.html",
        "https://hexdocs.pm/elixir/Atom.html",
      ]

  """
  def last_urls do
    GenServer.call(__MODULE__, :last_urls)
  end

  @doc """
  Adds a URL to the last visited URLs list.

  Returns `:ok`.

  ## Examples

      iex> Krptkn.Api.add_last_url("https://stallman.org/")
      :ok

  """
  def add_last_url(url) do
    GenServer.cast(__MODULE__, {:add_last_url, url})
  end

  @doc """
  Returns the memory state. To see the structure of the data, this is where it comes from:
  `:erlang.memory`
  """
  def memory do
    GenServer.call(__MODULE__, :memory)
  end

  # Init

  @doc "State of the API module. This is all the information being saved."
  def empty_state do
    %{
      url_count: 0,
      danger_count: 0,
      metadata_count: 0,
      fmetadata_count: 0,

      url_history: [],
      danger_history: [],
      metadata_history: [],
      fmetadata_history: [],

      http_responses: [],
      file_types: [],
      memory: [],
      processes: [],
      scheduler: [],

      metadata: [],
      dangerous_metadata: [],

      last_urls: [],
    }
  end

  @impl true
  def init([]) do
    schedule_rc()

    {:ok, empty_state()}
  end

  defp add_to_history(history, element, limit \\ 10) do
    if Enum.count(history) == limit do
      history = List.delete_at(history, limit - 1)
      [element | history]
    else
      [element | history]
    end
  end

  # Update state

  @impl true
  def handle_cast(:clear, _old_state) do
    {:noreply, empty_state()}
  end

  @impl true
  def handle_cast({:add_last_url, url}, state) do
    {:noreply, %{state | last_urls: Enum.slice([url | state.last_urls], 0..10)}}
  end

  @impl true
  def handle_cast({:add_response, http_response}, state) do
    {http_responses, res} = Enum.map_reduce(state.http_responses, :not_found, fn {response, count}, _acc ->
      if response == http_response do
        {{response, count + 1}, :found}
      end
    end)

    if res == :found do
      {:noreply, %{state | http_responses: http_responses}}
    else
      {:noreply, %{state | http_responses: [{http_response, 1} | state.http_responses]}}
    end
  end

  @impl true
  def handle_cast({:add_file_type, file_type}, state) do
    {file_types, res} = Enum.map_reduce(state.file_types, :not_found, fn {type, count}, acc ->
      if type == file_type do
        {{type, count + 1}, :found}
      else
        {{type, count}, acc}
      end
    end)

    if res == :found do
      {:noreply, %{state | file_types: file_types}}
    else
      {:noreply, %{state | file_types: [{file_type, 1} | state.file_types]}}
    end
  end

  @impl true
  def handle_cast({:add_metadata, metadata}, state) do
    {:noreply, %{state | metadata: [metadata | state.metadata]}}
  end

  @impl true
  def handle_cast({:add_dangerous_metadata, metadata}, state) do
    {:noreply, %{state | dangerous_metadata: [metadata | state.dangerous_metadata]}}
  end

  @impl true
  def handle_cast({:add, type}, state) do
    {:noreply, %{state | type => state[type] + 1}}
  end

  @impl true
  def handle_cast({:register_process, module, name, pid}, state) do
    Supervisor.which_children(pid)
    {:noreply, %{state | processes: [{module, name, pid, :online} | state.processes]}}
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

  # Automatic stuff
  defp schedule_rc do
    Process.send_after(self(), :regular_capture, 1_000)
  end

  @impl true
  def handle_info(:regular_capture, state) do
    # We save the memory state
    state = %{state | memory: [:erlang.memory | state.memory]}

    # We check if our processes are still online
    state = %{state | processes: Enum.map(state.processes, fn {module, name, pid, _state} ->
      new_state = case Process.alive?(pid) do
        true -> :online
        false -> :offline
      end

      {module, name, pid, new_state}
    end)}

    # We save the counts on their histories
    state = %{state | url_history: add_to_history(state.url_history, state.url_count)}
    state = %{state | danger_history: add_to_history(state.danger_history, state.danger_count)}
    state = %{state | metadata_history: add_to_history(state.metadata_history, state.metadata_count)}
    state = %{state | fmetadata_history: add_to_history(state.fmetadata_history, state.fmetadata_count)}

    # Save scheduler state
    scheduler_slice = :scheduler.utilization(:scheduler.sample_all())
    state = %{state | scheduler: add_to_history(state.scheduler, scheduler_slice, 30)}

    schedule_rc()

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error("Supervisor received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
