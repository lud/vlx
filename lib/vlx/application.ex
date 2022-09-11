defmodule Vlx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Vlx.MediaServer,
      # Start the Telemetry supervisor
      VlxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Vlx.PubSub},
      # Start the Endpoint (http/https)
      VlxWeb.Endpoint
      # Start a worker by calling: Vlx.Worker.start_link(arg)
      # {Vlx.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vlx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VlxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
