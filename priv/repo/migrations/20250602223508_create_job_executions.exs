defmodule Laki.Repo.Migrations.CreateJobExecutions do
  use Ecto.Migration

  def change do
    create table(:job_executions) do
      add :job_id, references(:cron_jobs, on_delete: :delete_all)
      add :status, :string, null: false
      add :started_at, :naive_datetime_usec
      add :completed_at, :naive_datetime_usec
      add :result, :text
      add :error, :text
      add :node_id, :string

      timestamps()
    end

    create index(:job_executions, [:job_id, :status])
  end
end
