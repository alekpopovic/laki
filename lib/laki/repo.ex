defmodule Laki.Repo do
  use Ecto.Repo,
    otp_app: :laki,
    adapter: Ecto.Adapters.Postgres
end
