defmodule Laki.Scheduler do
  use GenServer
  import Ecto.Query
  alias Laki.{Repo, Job, JobExecution}

  @check_interval 60_000 # Check every minute

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    #:pg.start(:laki)
    #:pg.join(:laki, node())

    schedule_check()
    {:ok, %{node_id: Atom.to_string(node())}}
  end

  def handle_info(:check_jobs, state) do
    check_and_execute_jobs(state.node_id)
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_jobs, @check_interval)
  end

  defp check_and_execute_jobs(node_id) do
    now = DateTime.utc_now()

    # Get jobs that need to run and try to acquire distributed lock
    query = from j in Job,
      where: j.enabled == true and j.next_run_at <= ^now,
      order_by: j.next_run_at

    jobs = Repo.all(query)

    for job <- jobs do
      if acquire_job_lock(job.id, node_id) do
        execute_job(job, node_id)
      end
    end
  end

  defp acquire_job_lock(job_id, node_id) do
    # Use PostgreSQL advisory locks for distributed coordination
    query = """
    UPDATE cron_jobs
    SET node_id = $1, updated_at = NOW()
    WHERE id = $2 AND (node_id IS NULL OR node_id = $1 OR updated_at < NOW() - INTERVAL '5 minutes')
    RETURNING id
    """

    case Repo.query(query, [node_id, job_id]) do
      {:ok, %{num_rows: 1}} -> true
      _ -> false
    end
  end

  defp execute_job(job, node_id) do
    execution = %JobExecution{}
    |> JobExecution.changeset(%{
      job_id: job.id,
      status: "running",
      started_at: DateTime.utc_now(),
      node_id: node_id
    })
    |> Repo.insert!()

    Task.start(fn -> run_job_task(job, execution) end)
  end

  defp run_job_task(job, execution) do
    try do
      module = String.to_existing_atom("Elixir.#{job.module}")
      function = String.to_existing_atom(job.function)
      args = if job.args, do: Jason.decode!(job.args), else: []

      result = apply(module, function, args)

      # Update execution as completed
      execution
      |> JobExecution.changeset(%{
        status: "completed",
        completed_at: DateTime.utc_now(),
        result: inspect(result)
      })
      |> Repo.update!()

      # Schedule next run
      update_next_run(job)

    rescue
      error ->
        execution
        |> JobExecution.changeset(%{
          status: "failed",
          completed_at: DateTime.utc_now(),
          error: Exception.format(:error, error, __STACKTRACE__)
        })
        |> Repo.update!()

        update_next_run(job)
    end
  end

  defp update_next_run(job) do
    case Crontab.CronExpression.Parser.parse(job.cron_expression) do
      {:ok, cron} ->
        next_run = Crontab.Scheduler.get_next_run_date(cron, DateTime.utc_now())

        job
        |> Job.changeset(%{
          next_run_at: next_run,
          last_run_at: DateTime.utc_now(),
          node_id: nil  # Release the lock
        })
        |> Repo.update!()

      {:error, _} ->
        # Disable job if cron expression is invalid
        job
        |> Job.changeset(%{enabled: false, node_id: nil})
        |> Repo.update!()
    end
  end
end
