defmodule Exrpc.Codec do
  @moduledoc false

  @type inbound :: list() | :mfa_list
  @type outbound :: {:goodrpc, any()} | {:badrpc, any()}

  @spec encode(term()) :: binary()
  def encode({:goodrpc, data}), do: "0" <> term_to_binary(data)
  def encode({:badrpc, :invalid_mfa}), do: "1"
  def encode({:badrpc, :invalid_message}), do: "2"
  def encode({:badrpc, reason}), do: "3" <> term_to_binary(reason)
  def encode(:mfa_list), do: "?"

  def encode([fun_id, args] = term) when is_integer(fun_id) and is_list(args),
    do: "!" <> term_to_binary(term)

  @spec decode(binary()) :: term()
  def decode("0" <> bin), do: {:goodrpc, binary_to_term(bin)}
  def decode("1"), do: {:badrpc, :invalid_mfa}
  def decode("2"), do: {:badrpc, :invalid_message}

  def decode("3" <> bin) do
    case binary_to_term(bin) do
      :decode_error -> :decode_error
      reason -> {:badrpc, reason}
    end
  end

  def decode("?"), do: :mfa_list

  def decode("!" <> bin) do
    with [fun_id, args] when is_integer(fun_id) and is_list(args) <- binary_to_term(bin) do
      [fun_id, args]
    end
  end

  def decode(_), do: :decode_error

  defp term_to_binary(term), do: :erlang.term_to_binary(term)

  defp binary_to_term(bin) do
    Plug.Crypto.non_executable_binary_to_term(bin, [:safe])
  rescue
    ArgumentError ->
      :decode_error
  end
end
