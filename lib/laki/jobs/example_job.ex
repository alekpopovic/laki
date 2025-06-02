defmodule Laki.Jobs.ExampleJob do
  require Logger

  def cleanup_old_logs do
    Logger.info("Running cleanup job...")
    # Your cleanup logic here
    :ok
  end

  def send_daily_report(email) do
    Logger.info("Sending daily report to #{email}")
    # Your report logic here
    {:ok, "Report sent"}
  end
end
