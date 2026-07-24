# frozen_string_literal: true

module SlurmCluster
  # Utility methods to format data for the cluster/partition templates.
  class ClusterHelper
    def state_class(partition_state)
      return 'bg-primary' if partition_state.nil?

      return 'bg-success' if partition_state.to_s.downcase == 'up'

      'bg-danger'
    end

    def state_icon(partition_state)
      return '<i class="fa fa-check-circle fa-fw text-success"></i>' if partition_state.to_s.downcase == 'up'

      '<i class="fa fa-times-circle fa-fw text-danger"></i>'
    end

    def nodes_class(nodes_metrics)
      available_percentage = nodes_metrics[1] / nodes_metrics[3].to_f
      if available_percentage > 0.45
        'bg-success'
      elsif available_percentage < 0.2
        'bg-danger'
      else
        'bg-warning'
      end
    end

    def cores_class(cores_metrics)
      available_percentage = cores_metrics[1] / cores_metrics[3].to_f
      if available_percentage > 0.45
        'bg-success'
      elsif available_percentage < 0.2
        'bg-danger'
      else
        'bg-warning'
      end
    end

    def memory_class(free_mem_mb, total_mem_mb)
      percentage = total_mem_mb.zero? ? 0.0 : free_mem_mb / total_mem_mb.to_f
      if percentage > 0.4
        'bg-success'
      elsif percentage < 0.2
        'bg-danger'
      else
        'bg-warning'
      end
    end

    def convert_mb_to_gb(mb_value)
      # Convert the input string to a float for division
      mb = mb_value.to_f

      # Perform the conversion from MB to GB
      gb = mb / 1024

      # Format the output as a string with two decimal places and append " GB"
      '%.1f' % gb
    end

  end
end
