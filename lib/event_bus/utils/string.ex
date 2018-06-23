defmodule EventBus.Util.String do
  @moduledoc false
  # String util for event bus

  @base62_map '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
  @max_str_reminder 238_327 # 'zzz'

  @doc """
  Generates partially sequential random id
  """
  @spec unique_id() :: String.t()
  def unique_id do
    base62_encode(now()) <> random()
  end

  def base62_encode(num) do
    new_num = div(num, 62)
    unless new_num == 0, do: merge(new_num, num), else: to_str(num)
  end

  defp merge(new_num, num) do
    base62_encode(new_num) <> to_str(num)
  end

  defp to_str(num) do
    << Enum.at(@base62_map, rem(num, 62)) >>
  end

  # Random string based on system's monotonic time
  defp random do
    System.monotonic_time(:nano_seconds)
    |> rem(1_000_000) # Take last 6 digits
    |> rem(@max_str_reminder) # Set max to 'zzz'
    |> base62_encode()
    |> String.pad_leading(3, "0")
  end

  defp now do
    System.os_time(:micro_seconds)
  end
end
