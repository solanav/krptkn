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

  # Process

  def register_process(module, name, pid) do
    GenServer.cast(__MODULE__, {:register_process, module, name, pid})
  end

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

  # Counts of state

  @spec add(:url | :danger | :metadata | :fmetadata) :: any
  def add(type) do
    type = String.to_atom("#{Atom.to_string(type)}_count")
    GenServer.cast(__MODULE__, {:add, type})
  end

  @spec count(:url | :danger | :metadata | :fmetadata) :: any
  def count(type) do
    type = String.to_atom("#{Atom.to_string(type)}_count")
    GenServer.call(__MODULE__, {:count, type})
  end

  @spec count_history(:url | :danger | :metadata | :fmetadata) :: any
  def count_history(type) do
    type = String.to_atom("#{Atom.to_string(type)}_history")
    GenServer.call(__MODULE__, {:history, type}) |> Enum.reverse()
  end

  # Dangerous metadata

  def add_dangerous_metadata(metadata) do
    GenServer.cast(__MODULE__, {:add_dangerous_metadata, metadata})
  end

  def dangerous_metadata do
    GenServer.call(__MODULE__, :dangerous_metadata)
  end

  # Scheduler

  def scheduler do
    GenServer.call(__MODULE__, :scheduler)
  end

  # File Type

  def add_file_type(file_type) do
    GenServer.cast(__MODULE__, {:add_file_type, file_type})
  end

  # Response Type

  def add_response_type(response_type) do
    GenServer.cast(__MODULE__, {:add_response, response_type})
  end

  # Last URLs

  def last_urls do
    GenServer.call(__MODULE__, :last_urls)
  end

  def add_last_url(url) do
    GenServer.cast(__MODULE__, {:add_last_url, url})
  end

  # Memory

  def memory do
    GenServer.call(__MODULE__, :memory)
  end

  # Init

  @impl true
  def init([]) do
    schedule_rc()

    state = %{
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

      dangerous_metadata: [],

      last_urls: [],
    }

    {:ok, state}
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
