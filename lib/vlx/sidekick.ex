defmodule Vlx.Sidekick do
  require Logger

  @todo "remove this module"

  @doc false
  def child_spec([]) do
    Task.Supervisor.child_spec(name: __MODULE__)
  end

  def spawn_task(f) when is_function(f, 0) do
    Logger.debug("starting task #{inspect(f)}")
    Task.Supervisor.start_child(__MODULE__, f, restart: :transient)
  end
end
