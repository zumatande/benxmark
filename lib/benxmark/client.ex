defmodule Benxmark.Client do
  @moduledoc """
  Client module
  """

  @client_config Application.get_env(:benxmark, :client, [])
  @api_key @client_config[:api_key]

  defmodule Response do
    defstruct ~w(status headers body)a
  end

  def get(url, path \\ "/", query_params \\ nil) do
    query =
      case query_params do
        nil -> nil
        _ -> URI.encode_query(query_params)
      end

    path_with_query = URI.to_string(%URI{path: path, query: query})

    {:ok, conn} = Mint.HTTP.connect(:http, url, 3001)
    {:ok, conn, _request_ref} = Mint.HTTP.request(conn, "GET", path_with_query, [{"x-api-key", @api_key}], nil)

    conn
    |> reduce_response_stream([])
    |> convert_response_stream_to_struct()
  end

  def reduce_response_stream(conn, responses) do
    conn
    |> receive_next_and_stream()
    |> handle_response_stream(responses)
  end

  def receive_next_and_stream(conn) do
    receive do
      message -> Mint.HTTP.stream(conn, message) # {:ok, conn, [response]} | {:error, conn, err, [response]}
    end
  end

  defp handle_response_stream({:ok, conn, resp}, responses) do
    if Enum.any?(resp, fn r ->
      elem(r, 0) == :done
    end) do
      Mint.HTTP.close(conn)
      resp ++ responses
    else
      reduce_response_stream(conn, resp ++ responses)
    end
  end

  defp handle_response_stream({:error, conn, _err, resp}, responses) do
    Mint.HTTP.close(conn)
    resp ++ responses
  end

  def convert_response_stream_to_struct(responses) do
    Enum.reduce(responses, %Response{}, fn
      {:status, _ref, status}, acc -> Map.put(acc, :status, status)
      {:data, _ref, data}, acc -> Map.put(acc, :body, data)
      {:headers, _ref, headers}, acc -> Map.update(acc, :headers, headers, &[headers | &1])
      {:done, _ref}, acc -> acc
    end)
  end
end
