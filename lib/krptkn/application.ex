defmodule Krptkn.Application do
  import ExProf.Macro

  use Application

  @starting_page "https://stallman.org"
  @producers 12
  @consumers 24

  def start(_type, _args) do
    # Start the queue
    children = [{Krptkn.UrlQueue, @starting_page}]

    # Start the producers
    {names, producers} = Enum.reduce(0..@producers-1, {[], []}, fn i, {n, p} ->
      name = String.to_atom("p#{i}")
      {
        [name | n],
        [Supervisor.child_spec({Krptkn.Spider, name}, id: name) | p]
      }
    end)
    children = children ++ producers

    # Start the consumers
    children = children ++ Enum.map(0..@consumers-1, fn i ->
      name = String.to_atom("c#{i}")
      Supervisor.child_spec({Krptkn.Scholar, names}, id: name)
    end)

    # Start the HTTP client
    HTTPoison.start()

    # Start erlangs viewer
    :observer.start()

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
