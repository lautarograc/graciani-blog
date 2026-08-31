module ApplicationHelper
  def format_engaged_duration(seconds)
    return "0s" if seconds <= 0

    minutes, secs = seconds.divmod(60)
    minutes.positive? ? "#{minutes}m #{secs}s" : "#{secs}s"
  end
end
