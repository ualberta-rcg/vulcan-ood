# frozen_string_literal: true

module SlurmCluster
  # Service to manage retrieving and caching cluster data.
  class ClusterService
    attr_reader :cluster

    def initialize
      @cluster = Configuration.job_clusters.select(&:slurm?).first
    end

    def partitions
      Rails.cache.fetch('cluster_widget_partitions', expires_in: 1.hours) do
        read_partitions
      end
    end

    private

    def read_partitions
      # CALCULATE PARTITION METRICS BASED ON NODE DATA
      nodes = @cluster.job_adapter.nodes
      partitions = { }
      nodes.each do |node_info|
        partition_info = partitions.fetch(node_info.partition, { free_memory: 0, total_memory: 0 })
        partition_info[:partition] = node_info.partition
        partition_info[:partition_state] = node_info.partition_state
        # SELECT THE MAXIMUM VALUE FOR FREE MEMORY IN THE PARTITION
        if node_info.free_memory > partition_info.fetch(:free_memory)
          partition_info[:free_memory] = node_info.free_memory
          partition_info[:total_memory] = node_info.total_memory
        end
        # CORES BY STATE - AGGREGATE ALL
        # THIS IS AN ARRAY WITH THE NUMBER OF PROCESSORS IN EACH STATE:
        # procs_by_state[0] = USED CORES
        # procs_by_state[1] = FREE CORES
        # procs_by_state[2] = OTHER CORES
        # procs_by_state[3] = TOTAL CORES
        partition_info[:procs_by_state] = node_info.procs_by_state.zip(partition_info.fetch(:procs_by_state, [0, 0, 0, 0])).map { |a, b| a + b }
        # NODES BY STATE - AGGREGATE ALL
        # THIS IS AN ARRAY WITH THE NUMBER OF PROCESSORS IN EACH STATE:
        # nodes_by_state[0] = USED NODES
        # nodes_by_state[1] = FREE NODES
        # nodes_by_state[2] = OTHER NODES
        # nodes_by_state[3] = TOTAL NODES
        partition_info[:nodes_by_state] = node_info.nodes_by_state.zip(partition_info.fetch(:nodes_by_state, [0, 0, 0, 0])).map { |a, b| a + b }
        partitions[node_info.partition] = partition_info
      end

      [Time.now, partitions.values]
    end
  end
end
