defmodule Krptkn.Parsers.Pdf do
  @moduledoc """
  This module uses naive techniques to extract the metadata from PDFs

  Implements the Parser behaviour
  """

  @behaviour Krptkn.Parser

  defp find(file, regex) do
    file
    |> Stream.with_index
    |> Stream.map(fn {text, line} ->
      {line, Regex.run(regex, text, capture: :all_but_first)}
    end)
    |> Stream.filter(fn
      {_, nil} -> false
      {_, _} -> true
    end)
    |> Enum.to_list
  end

  defp get_line(file, line) do
    file
    |> Enum.to_list
    |> Enum.at(line)
  end

  defp find_info(file) do
    info_regex = ~r/\/Info ([0-9]+) [0-9]+/

    {_, text} = find(file, info_regex) |> Enum.at(0)
    Enum.map(text, fn pos -> String.to_integer(pos) end)
  end

  defp get_obj(file, code) do
    info_code_regex = ~r/#{code} [0-9]+ obj(.*)/

    {line, _} = find(file, info_code_regex) |> Enum.reverse |> Enum.at(0)
    obj = get_line(file, line + 1)

    :binary.bin_to_list(obj)
    |> Enum.map(fn b -> <<b::utf8>> end)
    |> Enum.join
  end

  @doc """
  Finds the metadata in PDFs and turns it into a map.

  Returns a dictionary with PDF's data.

  ## Examples

      iex> f = File.stream!("TFG.pdf")
      iex> info = Krptkn.Parsers.Pdf.get_info(f)
      iex> IO.inspect info
      %{
        Author: "Antonio Solana Vera",
        CreationDate: "D:20210506115600",
        Keywords: "Metadatos,TFG",
        Subject: "Trabajo fin de Grado",
        Title: "Análisis de metadatos"
      }

  """
  @impl Krptkn.Parser
  def get_info(file) do
    info_regex = ~r/\/(.*?) ?\((.*?)\)/

    code = find_info(file) |> Enum.at(0)
    obj = get_obj(file, code)

    Regex.scan(info_regex, obj, capture: :all_but_first)
    |> Enum.map(fn [key, value] ->
      {String.to_atom(key), value}
    end)
    |> Map.new
  end
end
