# frozen_string_literal: true

module SlurmMetrics
  # Utility methods to format data for the metrics templates.
  class MetricsHelper

    def progress_title(total, label, value)
      "#{label} #{metrics_round(total, value)}%"
    end

    def period_text
      days = SlurmMetrics::MetricsService::METRICS_PERIOD / 1.day
      "Period: Last #{days} days"
    end

    def period_title(from_text, to_text)
      days = SlurmMetrics::MetricsService::METRICS_PERIOD / 1.day
      "Period: Last #{days} days - from #{from_text} to #{to_text}"
    end

    def metrics_round(total, value)
      value = total.zero? ? 0.0 : value / total.to_f
      # ENSURE AT LEAST 1% IS SHOWN FOR SMALL NUMBERS
      value = value < 0.01 ? value.ceil(2) : value.round(2)
      (value * 100).to_i
    end

    def metrics_ceil(total, value)
      value = total.zero? ? 0.0 : value / total.to_f
      (value.ceil(1) * 100).to_i
    end

    def efficiency_class(efficiency_value)
      return 'bg-primary' if efficiency_value.nil?

      if efficiency_value > 74
        return 'bg-success'
      elsif efficiency_value < 25
        return 'bg-danger'
      else
        return 'bg-warning'
      end
    end

    def efficiency_icon(efficiency_value)
      if efficiency_value > 74
        return '<i class="fa fa-check-circle fa-fw text-success" title="Good efficiency"></i>'
      elsif efficiency_value < 25
        return '<i class="fa fa-times-circle fa-fw text-danger" title="Bad efficiency, consider adjusting the parameter values"></i>'
      else
        return '<i class="fa fa-exclamation-circle fa-fw text-warning" title="Medium efficiency, consider adjusting the parameter values"></i>'
      end
    end

    def fairshare_class(fairshare_value)
      fairshare_value = fairshare_value.to_s.to_f

      if fairshare_value > 0.79
        return "bg-success"
      elsif fairshare_value < 0.5
        return "bg-danger"
      else
        return "bg-warning"
      end
    end

    def format_duration(seconds)
      return sprintf("00m:%02ds", seconds) if seconds < 60.0

      hours = seconds / 3600
      minutes = (seconds % 3600) / 60

      sprintf("%02dH:%02dm", hours, minutes)
    end

    # FROM TESTING
    # SLURM METRICS TAKE SOMETIME TO APPEAR AFTER A JOB IS COMPLETED/CANCELLED
    def metrics_waiting_elapsed(completed_time)
      Time.now.to_i - completed_time > 10
    end

    def session_metrics_enabled?(user_configuration)
      metrics_configuration = user_configuration.send(:fetch, :session_metrics_enabled, false)
      ::Configuration.send(:to_bool, metrics_configuration)
    end
  end
end
