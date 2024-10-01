defmodule MessageAccumulator do
  def get_message(<<size::size(16), _data::binary-size(size), _extra_raw_message::binary>> = raw_message, accumulator) when size <= 0x1FFF do # consider length larger than roughly 8kb to be incorrect length
    size = size + 2
    <<data::binary-size(size), extra_raw_message::binary>> = raw_message
    accumulator = [data | accumulator]
    get_message(extra_raw_message, accumulator)
  end

  def get_message(<<size::size(16), _data::binary-size(size)>> = raw_message, accumulator) when size <= 0x1FFF do
    size = size + 2
    <<data::binary-size(size)>> = raw_message
    accumulator = [data | accumulator]
    get_message(<<>>, accumulator)
  end

  def get_message(<<size::size(16), _data::binary>> = raw_message, accumulator) when size <= 0x1FFF do
    {accumulator, raw_message} # return the list of messages and the leftover
  end

  def get_message(<<>>, accumulator) do
    {accumulator, <<>>} # return the list of messages and the leftover
  end

  def get_message(_raw_message, accumulator) do # invalid header value
    {accumulator, <<>>} # return the list of messages and reset the current message value
  end
end
