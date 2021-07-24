defmodule Krptkn.Parser do
  @doc """
  Extracts the metadata from a file and returns it as a Map
  """
  @callback get_info(binary()) :: map()
end
