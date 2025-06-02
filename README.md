# Laki

Cron Jobs Scheduller

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `laki` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:laki, "~> 0.1.0"}
  ]
end
```
## Features

- Job Persistence: Jobs are stored in PostgreSQL with full CRUD operations

- Distributed Scheduling: Uses PostgreSQL advisory locks and node coordination to prevent duplicate job execution across multiple nodes

- Job Queues: Job executions are tracked in a separate table with status, results, and error handling

- Dynamic Job Creation: Jobs can be created, updated, enabled/disabled at runtime through the API

## Architecture Components

- Database Schema: Two main tables - cron_jobs for job definitions and job_executions for execution tracking

- Scheduler GenServer: Main coordinator that checks for due jobs every minute and manages distributed locking

- Job Execution: Async task execution with proper error handling and result tracking
Public API: Clean interface for job management operations

Usage Examples

## Create a job

```elixir
Laki.create_simple_job(
  "cleanup_logs", 
  "0 2 * * *",  # Daily at 2 AM
  "Laki.Jobs.ExampleJob", 
  "cleanup_old_logs"
)
```

## Create job with arguments

```elixir
Laki.create_simple_job(
  "daily_report",
  "0 9 * * 1-5",  # Weekdays at 9 AM
  "Laki.Jobs.ExampleJob",
  "send_daily_report",
  ["admin@company.com"]
)
```

## Manage jobs

```elixir
Laki.disable_job("cleanup_logs")
Laki.enable_job("cleanup_logs")
Laki.get_job_executions("daily_report", 10)
```

## Distributed Coordination

The scheduler uses PostgreSQL row-level locking with node IDs and timestamps to ensure only one node executes each job. Jobs are automatically released after 5 minutes to handle node failures.

Configuration Required

## Add to your config.exs:

```elixir
config :laki, Laki.Repo,
  database: "your_database",
  username: "username",
  password: "password",
  hostname: "localhost"

config :laki, ecto_repos: [Laki.Repo]
```