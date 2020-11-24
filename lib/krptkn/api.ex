defmodule Krptkn.Api do
  @moduledoc """
  This "API" allows to save meta information about Krptkn's state
  and exposes functions so phoenix can get the information.
  """

  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec add(:url | :danger | :metadata | :fmetadata) :: any
  def add(type) do
    GenServer.cast(__MODULE__, type)
  end

  @spec count(:url | :danger | :metadata | :fmetadata) :: any
  def count(type) do
    GenServer.call(__MODULE__, type)
  end

  def add_file_type(file_type) do
    GenServer.cast(__MODULE__, {:add_file_type, file_type})
  end

  def add_response_type(response_type) do
    GenServer.cast(__MODULE__, {:add_response, response_type})
  end

  def memory do
    GenServer.call(__MODULE__, :memory)
  end

  def reductions do
    GenServer.call(__MODULE__, :reductions)
  end

  @impl true
  def init([]) do
    schedule_rc()

    state = %{
      url_count: 0,
      danger_count: 0,
      metadata_count: 0,
      fmetadata_count: 0,
      http_responses: [],
      file_types: [],
      memory: [],
      reductions: [],
    }

    {:ok, state}
  end

  # No reply
  @impl true
  def handle_cast(:url, state) do
    {:noreply, %{state | url_count: state.url_count + 1}}
  end

  @impl true
  def handle_cast(:danger, state) do
    {:noreply, %{state | danger_count: state.danger_count + 1}}
  end

  @impl true
  def handle_cast(:metadata, state) do
    {:noreply, %{state | metadata_count: state.metadata_count + 1}}
  end

  @impl true
  def handle_cast(:fmetadata, state) do
    {:noreply, %{state | fmetadata_count: state.fmetadata_count + 1}}
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
    {file_types, res} = Enum.map_reduce(state.file_types, :not_found, fn {type, count}, _acc ->
      if type == file_type do
        {{type, count + 1}, :found}
      end
    end)

    if res == :found do
      {:noreply, %{state | file_types: file_types}}
    else
      {:noreply, %{state | file_types: [{file_type, 1} | state.file_types]}}
    end
  end

  # Yes reply
  @impl true
  def handle_call(:url, _from, state) do
    {:reply, state.url_count, state}
  end

  @impl true
  def handle_call(:danger, _from, state) do
    {:reply, state.danger_count, state}
  end

  @impl true
  def handle_call(:metadata, _from, state) do
    {:reply, state.metadata_count, state}
  end

  @impl true
  def handle_call(:fmetadata, _from, state) do
    {:reply, state.fmetadata_count, state}
  end

  @impl true
  def handle_call(:memory, _from, state) do
    {:reply, state.memory, state}
  end

  @impl true
  def handle_call(:reductions, _from, state) do
    {:reply, state.reductions, state}
  end

  defp get_reductions do
    :erlang.processes()
    |> Enum.map(fn pid ->
      info = :erlang.process_info(pid)
      %{
        reductions: info[:reductions],
        name: info[:registered_name],
        current_function: info[:current_function],
      }
    end)
    |> Enum.sort(&(&1[:reductions] >= &2[:reductions]))
    |> Enum.take(5)
  end

  # Automatic stuff
  @impl true
  def handle_info(:regular_capture, state) do
    # We save the memory state
    state = %{state | memory: [:erlang.memory | state.memory]}

    # We save the reduction state
    state = %{state | reductions: [get_reductions() | state.reductions]}

    schedule_rc()

    {:noreply, state}
  end

  defp schedule_rc do
    Process.send_after(self(), :regular_capture, 1_000)
  end
end
