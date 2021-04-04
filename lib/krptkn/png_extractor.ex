defmodule Krptkn.PngExtractor do
  @moduledoc """
  This module uses naive techniques to extract the metadata inside PNG
  files. It also uses Exexif if exif info is found inside the PNG file.
  """

  @image_start_marker 0x89_50_4E_47_0D_0A_1A_0A
  @tEXt 0x74_45_58_74
  @iTXt 0x69_54_58_74
  @zTXt 0x7A_54_58_74

  defstruct [:width, :height, :bit_depth, :color_type, :compression, :filter, :interlace, :chunks]

  @doc """
  Turns EXIF data into map. Uses Exexif.

  Returns a dictionary with EXIF data.

  ## Examples

      iex> Krptkn.PngExtractor.exifstr2map(data)
      %{
        size: "160x160",
        "Created By Software": "Adobe Photoshop CC 2017 (Macintosh)",
      }

  """
  def exifstr2map(data) do
    data = String.split(data, "\n")

    # Get the lenght
    <<_::32, len::binary()>> = Enum.at(data, 2)
    {len, _} = Integer.parse(len, 16)

    # Turn the ascii hex to binary
    bin = Enum.slice(data, 3..Enum.count(data))
    |> Enum.flat_map(fn p ->
      String.codepoints(p)
      |> Enum.chunk_every(2)
      |> Enum.map(fn [a, b] ->
        {num, _s} = Integer.parse(a <> b, 16)
        num
      end)
    end)
    |> :binary.list_to_bin()

    # Add APP1 so Exexif doesn't complain
    bin = <<0xFFE1::16>> <> <<len::16>> <> bin

    {:ok, data} = Exexif.read_exif(bin)
    data
  end

  defp ztxt2map(raw_profile_type_exif) do
    # Decompress the field (its zTXt)
    z = :zlib.open()

    :zlib.inflateInit(z)
    <<_type::8, zlib_text::binary()>> = raw_profile_type_exif

    data = :zlib.inflate(z, zlib_text)
    |> Enum.join()

    :zlib.inflateEnd(z)

    exifstr2map(data)
  end

  @doc """
  Extracts EXIF metadata from a PNG buffer (compressed or not).

  Returns a dictionary with EXIF data.

  ## Examples

      iex> Krptkn.PngExtractor.extract_from_png_buffer(binary_data)
      %{
        size: "160x160",
        "Created By Software": "Adobe Photoshop CC 2017 (Macintosh)",
      }

  """
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
      :binary.matches(chunks, <<@iTXt::32>>) ++
      :binary.matches(chunks, <<@zTXt::32>>)

    # We get the position of the tEXt chunk
    case chunk_positions do
      [] -> {:error, %{}}
      m -> {:ok, Enum.map(m, fn {part, len} ->
        # We get the lenght of the tEXt chunk
        <<num::32>> = :binary.part(chunks, {part - 4, len})

        # We read the tEXt chunk
        chunk = :binary.part(chunks, {part + 4, num})
        |> :binary.split(<<0::8>>)

        # If we have raw profile type exif, extract it
        case chunk do
          ["Raw profile type exif", v] -> {"Raw profile type exif", ztxt2map(v)}
          [k, v] -> {k, v}
        end
      end)
      |> Map.new}
    end
  end
end
