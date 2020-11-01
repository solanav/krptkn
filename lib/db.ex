defmodule Krptkn.Db do
  @moduledoc """
  This module abstracts database functions
  """

  def insert_metadata(url, type, metadata) do
    session = Application.get_env(:krptkn, Krptkn.Application)[:session_name]
    Postgrex.query!(:psql, "INSERT INTO metadata (session, url, type, metadata) VALUES ($1, $2, $3, $4)", [session, url, type, metadata])
  end
  
  def insert_url(url) do
    session = Application.get_env(:krptkn, Krptkn.Application)[:session_name]
    Postgrex.query!(:psql, "INSERT INTO visited_urls (session, url) VALUES ($1, $2)", [session, url])
  end
end