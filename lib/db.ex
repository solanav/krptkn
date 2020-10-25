defmodule Krptkn.Db do
  @moduledoc """
  This module abstracts database functions
  """

  def insert_mongo(collection, object) do
    Mongo.insert_one(:mongo, collection, object)
  end
end
