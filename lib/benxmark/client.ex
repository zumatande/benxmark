defmodule Benxmark.Client do
  @moduledoc """
  Client module
  """

  def get(url) do
    HTTPoison.get(url, ["x-api-key": "ef31e2ba-45e4-b024-62c0-2e5be1f8618b"])
  end
end
