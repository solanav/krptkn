defmodule Krptkn.Metadata.PngExtractor do
  @image_start_marker 0x89_50_4E_47_0D_0A_1A_0A
  @tEXt 0x74_45_58_74
  @iEXt 0x69_54_58_74
  @zEXt 0x7A_54_58_74

  defstruct [:width, :height, :bit_depth, :color_type, :compression, :filter, :interlace, :chunks]

  def extract_from_png_buffer(
    <<
      @image_start_marker::64,
      _lenght::32,
      "IHDR",
      _width::32,
      _height::32,
      _bit_depth,
      _color_type,
      _compression_method,
      _filter_method,
      _interlace_method,
      _crc::32,
      chunks::binary()
    >>
  ) do
    chunk_positions =
      :binary.matches(chunks, <<@tEXt::32>>) ++
      :binary.matches(chunks, <<@iEXt::32>>) ++
      :binary.matches(chunks, <<@zEXt::32>>)

    # We get the position of the tEXt chunk
    case chunk_positions do
      [] -> {:error, %{}}
      m -> {:ok, Enum.map(m, fn {part, len} ->
        # We get the lenght of the tEXt chunk
        <<num::32>> = :binary.part(chunks, {part - 4, len})

        # We read the tEXt chunk
        chunk = :binary.part(chunks, {part + 4, num})
        |> :binary.split(<<0::8>>)

        List.to_tuple(chunk)
      end)
      |> Map.new}
    end
  end
end
