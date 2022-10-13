defmodule Vlx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Vlx.Sidekick,
      {Phoenix.PubSub, name: Vlx.PubSub},
      Vlx.MediaServer,
      Vlx.VlcRemote,
      Vlx.RCMonitor,
      VlxWeb.Telemetry,
      Vlx.IpDisplay,
      VlxWeb.Endpoint
    ]

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
