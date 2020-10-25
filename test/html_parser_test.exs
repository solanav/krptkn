defmodule KrptknTest do
  use ExUnit.Case
  doctest Krptkn

  test "get_urls 0" do
    {:ok, html} = File.read("test/test_files/test0.html")
    len = Krptkn.HtmlParser.get_urls("https://stallman.org/", html)
    |> Enum.count()

    assert len > 220
  end
end
