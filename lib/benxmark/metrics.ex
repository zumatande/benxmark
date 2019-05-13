defmodule Benxmark.Metrics do
  @moduledoc """
  Thin wrapper for Histogrex
  """
  use Histogrex

  histogrex :api_v3_response, min: 1.0, max: 10_000.0, precision: 5
  histogrex :load_duration, min: 0.1, max: 50.0, precision: 3
  histogrex :load_volume, min: 1, max: 10_000, precision: 5

  def start_link(_opts), do: start_link()
end
