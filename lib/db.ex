defmodule Krptkn.Db do
  def insert_mongo(collection, object) do
    Mongo.insert_one(:mongo, collection, object)
  end
end
