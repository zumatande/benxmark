defmodule Benxmark do
  @moduledoc """
  Documentation for Benxmark.
  """

  alias Benxmark.{
    Client,
    Metrics
  }

  @doc """
  Hello world.

  ## Examples

      iex> Benxmark.hello()
      :world

  """
  def hello do
    :world
  end

  def run(base_url, queryable, concurrent \\ :concurrent)
  def run(base_url, queryable, concurrent)
     when is_map(queryable) do
    base_url
    queryable
    concurrent
  end

  def run(base_url, queryable, _concurrent)
     when is_list(queryable) do
    uri = URI.parse(base_url)

    start_time = System.monotonic_time(:millisecond)

    queryable
    |> Enum.map(fn q ->
      Task.async(__MODULE__, :timed_fetch, [uri, q])
    end)
    |> Task.yield_many()

    end_time = System.monotonic_time(:millisecond)
    duration = abs(end_time - start_time)
    volume = length(queryable)

    Metrics.record(:load_duration, duration)
    Metrics.record(:load_volume, volume)

    {:ok, %{
      duration: duration,
      volume: volume,
      mean: Metrics.mean(:api_v3_response),
      max: Metrics.max(:api_v3_response),
      min: Metrics.min(:api_v3_response),
      percentile: %{
        50 => Metrics.value_at_quantile(:api_v3_response, 50.0),
        60 => Metrics.value_at_quantile(:api_v3_response, 60.0),
        70 => Metrics.value_at_quantile(:api_v3_response, 70.0),
        80 => Metrics.value_at_quantile(:api_v3_response, 80.0),
        90 => Metrics.value_at_quantile(:api_v3_response, 90.0),
        95 => Metrics.value_at_quantile(:api_v3_response, 95.0),
        99 => Metrics.value_at_quantile(:api_v3_response, 99.0),
      }
    }}
  end

  def run(base_url, file, _concurrent)
     when is_binary(file) do
    queryable = parse_properties_file(file)
    uri = URI.parse(base_url)

    start_time = System.monotonic_time(:millisecond)

    queryable
    |> Enum.map(fn q ->
      Task.async(__MODULE__, :timed_fetch, [uri, q])
    end)
    |> Task.yield_many(50_000)

    end_time = System.monotonic_time(:millisecond)
    duration = abs(end_time - start_time)
    volume = length(queryable)

    Metrics.record(:load_duration, duration)
    Metrics.record(:load_volume, volume)

    {:ok, %{
      duration: duration,
      volume: volume,
      mean: Metrics.mean(:api_v3_response),
      max: Metrics.max(:api_v3_response),
      min: Metrics.min(:api_v3_response),
      percentile: %{
        50 => Metrics.value_at_quantile(:api_v3_response, 50.0),
        60 => Metrics.value_at_quantile(:api_v3_response, 60.0),
        70 => Metrics.value_at_quantile(:api_v3_response, 70.0),
        80 => Metrics.value_at_quantile(:api_v3_response, 80.0),
        90 => Metrics.value_at_quantile(:api_v3_response, 90.0),
        95 => Metrics.value_at_quantile(:api_v3_response, 95.0),
        99 => Metrics.value_at_quantile(:api_v3_response, 99.0),
      }
    }}
  end

  def timed_fetch(uri, queryable, started \\ nil)

  def timed_fetch(uri, queryable, nil) do
    query = URI.encode_query(queryable)
    url = URI.to_string(%{uri | query: query, path: "/hotel_rooms"})

    started = System.monotonic_time(:millisecond)

    {:ok, %{body: body}} = Client.get(url)
    resp = Jason.decode!(body)

    case resp do
      %{"status" => "in-progress"} ->
        timed_fetch(uri, queryable, started)

      _complete ->
        ended = System.monotonic_time(:millisecond)
        elapsed = abs(ended - started)
        Task.start(fn -> Metrics.record(:api_v3_response, elapsed) end)
        resp
    end
  end

  def timed_fetch(uri, queryable, started) when is_integer(started) do
    query = URI.encode_query(queryable)
    url = URI.to_string(%{uri | query: query, path: "/hotel_rooms"})

    {:ok, %{body: body}} = Client.get(url)
    resp = Jason.decode!(body)

    case resp do
      %{"status" => "in-progress"} ->
        timed_fetch(uri, queryable, started)

      _complete ->
        ended = System.monotonic_time(:millisecond)
        elapsed = abs(ended - started)
        Task.start(fn -> Metrics.record(:api_v3_response, elapsed) end)
        resp
    end
  end

  def parse_properties_file(file) do
    [_title | entries] =
      file
      |> File.read!()
      |> String.split()
      |> Enum.map(&String.trim(&1, "\""))

    Enum.map(entries, &Map.put(%{
      check_in_date: "2019-06-10",
      check_out_date: "2019-06-12",
      room_count: 1,
      adult_count: 2,
      currency: "USD",
      source_market: "US"
    }, :hotel_id, &1))
  end
end
