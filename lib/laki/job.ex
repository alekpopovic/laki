defmodule Laki.Job do
  use Ecto.Schema
  import Ecto.Changeset

  alias Laki.JobExecution, as: JobExecution

  schema "cron_jobs" do
    field :name, :string
    field :cron_expression, :string
    field :module, :string
    field :function, :string
    field :args, :string
    field :enabled, :boolean, default: true
    field :next_run_at, :utc_datetime
    field :last_run_at, :utc_datetime
    field :node_id, :string
    field :metadata, :map, default: %{}

    has_many :executions, JobExecution

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:name, :cron_expression, :module, :function, :args, :enabled, :metadata])
    |> validate_required([:name, :cron_expression, :module, :function])
    |> unique_constraint(:name)
    |> validate_cron_expression()
    |> calculate_next_run()
  end

  defp validate_cron_expression(changeset) do
    case get_change(changeset, :cron_expression) do
      nil -> changeset
      expression ->
        case Crontab.CronExpression.Parser.parse(expression) do
          {:ok, _} -> changeset
          {:error, _} -> add_error(changeset, :cron_expression, "invalid cron expression")
        end
    end
  end

  defp calculate_next_run(changeset) do
    case get_change(changeset, :cron_expression) do
      nil -> changeset
      expression ->
        case Crontab.CronExpression.Parser.parse(expression) do
          {:ok, cron} ->
            next_run = Crontab.Scheduler.get_next_run_date(cron, DateTime.utc_now())
            put_change(changeset, :next_run_at, next_run)
          {:error, _} -> changeset
        end
    end
  end
end
