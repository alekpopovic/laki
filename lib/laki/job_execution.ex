defmodule Laki.JobExecution do
  use Ecto.Schema
  import Ecto.Changeset

  alias Laki.Job, as: Job

  @timestamps_opts [type: :naive_datetime_usec]

  schema "job_executions" do
    field :status, :string
    field :started_at, :naive_datetime_usec
    field :completed_at, :naive_datetime_usec
    field :result, :string
    field :error, :string
    field :node_id, :string

    belongs_to :job, Job

    timestamps()
  end

  def changeset(execution, attrs) do
    execution
    |> cast(attrs, [:job_id, :status, :started_at, :completed_at, :result, :error, :node_id])
    |> validate_required([:job_id, :status])
  end
end
