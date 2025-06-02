defmodule Laki.Application do
  use Application

  def start(_type, _args) do
    children = [
      Laki.Repo,
      Laki.Scheduler
    ]

    opts = [strategy: :one_for_one, name: Laki.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
