defmodule Laki do
  alias Laki.{Repo, Job, JobExecution}
  import Ecto.Query

  def create_job(attrs) do
    %Job{}
    |> Job.changeset(attrs)
    |> Repo.insert()
  end

  def update_job(name, attrs) when is_binary(name) do
    case get_job_by_name(name) do
      nil -> {:error, :not_found}
      job ->
        job
        |> Job.changeset(attrs)
        |> Repo.update()
    end
  end

  def delete_job(name) when is_binary(name) do
    case get_job_by_name(name) do
      nil -> {:error, :not_found}
      job -> Repo.delete(job)
    end
  end

  def enable_job(name) when is_binary(name) do
    update_job(name, %{enabled: true})
  end

  def disable_job(name) when is_binary(name) do
    update_job(name, %{enabled: false})
  end

  def list_jobs do
    Repo.all(Job)
  end

  def get_job_by_name(name) do
    Repo.get_by(Job, name: name)
  end

  def get_job_executions(job_name, limit \\ 50) do
    query = from e in JobExecution,
      join: j in Job, on: e.job_id == j.id,
      where: j.name == ^job_name,
      order_by: [desc: e.inserted_at],
      limit: ^limit,
      preload: [:job]

    Repo.all(query)
  end

  def create_simple_job(name, cron_expression, module, function, args \\ []) do
    create_job(%{
      name: name,
      cron_expression: cron_expression,
      module: module,
      function: function,
      args: Jason.encode!(args)
    })
  end
end
