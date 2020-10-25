defmodule Krptkn.Db do
  def insert_mongo(collection, object) do
    exif = Enum.map(object, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)

    Mongo.insert_one(:mongo, collection, exif)
  end
end
