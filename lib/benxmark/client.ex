defmodule Benxmark.Client do
  @moduledoc """
  Client module
  """

  @opts [timeout: 50_000, recv_timeout: 50_000]

  def get(url) do
    HTTPoison.get(url, ["x-api-key": "ef31e2ba-45e4-b024-62c0-2e5be1f8618b"], @opts)
  end
end
