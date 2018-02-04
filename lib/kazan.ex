defmodule Kazan do
  @moduledoc """
  Kazan is a Kubernetes API client for Elixir.

  ### Module Overview

  - `Kazan.Models` contains structs that can be sent and received by kube.
  - `Kazan.Apis` contains modules that contain functions for building requests
    to send to the kube API.
  - `Kazan.Client` is responsible for actually sending those requests.

  See the [README](readme.html) for example usage.
  """

  @doc """
  Makes a request against a kube server.

  The server must be set in the kazan config.
  """
  defdelegate run(request), to: Kazan.Client

  @doc """
  Makes a request against a kube server.

  The server should be set in the kazan config or provided in the options.

  ### Options

  * `server` - A `Kazan.Server` struct that defines which server we should send
  this request to. This will override any server provided in the Application
  config.
  """
  defdelegate run(request, opts), to: Kazan.Client

  @doc """
  Like `run/2`, but raises on Error.  See `run/2` for more details.
  """
  @spec run!(Request.t, Keyword.t) :: struct | no_return
  defdelegate run!(request, opts), to: Kazan.Client

  @doc """
  Like `run/1`, but raises on Error.  See `run/1` for more details.
  """
  @spec run!(Request.t) :: struct | no_return
  defdelegate run!(request), to: Kazan.Client
end
