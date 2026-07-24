# Slurm Adapter Extensions to extract metrics with sacct
Rails.application.config.after_initialize do
  Rails.logger.info 'Executing NodeInfo extension ...'
  require 'ood_core/job/node_info'

  module OodCore
    module Job
      class NodeInfo
        attr_reader :partition, :partition_state, :procs_by_state, :nodes_by_state, :total_memory, :free_memory

        def initialize(name:, partition: nil, partition_state: nil, procs: nil, procs_by_state: [], nodes_by_state: [], features: [], total_memory: nil, free_memory: nil, **_)
          @name  = name.to_s
          @partition = partition.to_s
          @partition_state = partition_state.to_s
          @procs = procs && procs.to_i
          @procs_by_state = procs_by_state.to_a.map(&:to_i)
          @nodes_by_state = nodes_by_state.to_a.map(&:to_i)
          @total_memory = total_memory.to_i
          @free_memory = free_memory.to_i
          @features = features.to_a
        end

      end
    end
  end



  Rails.logger.info 'Executing NodeInfo extension completed'
end