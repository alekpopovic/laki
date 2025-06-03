defmodule Laki.Repo.Migrations.CreateCronJobs do
  use Ecto.Migration

  def change do
    create table(:cron_jobs) do
      add :name, :string, null: false
      add :cron_expression, :string, null: false
      add :module, :string, null: false
      add :function, :string, null: false
      add :args, :text
      add :enabled, :boolean, default: true
      add :next_run_at, :naive_datetime_usec
      add :last_run_at, :naive_datetime_usec
      add :node_id, :string
      add :metadata, :map, default: %{}

      timestamps()
    end

    create unique_index(:cron_jobs, [:name])
    create index(:cron_jobs, [:enabled, :next_run_at])
    create index(:cron_jobs, [:node_id])
  end
end
