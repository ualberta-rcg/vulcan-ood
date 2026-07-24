# Slurm Adapter Extensions to extract metrics with sacct
Rails.application.config.after_initialize do
  Rails.logger.info 'Executing Slurm nodes method extension ...'
  require 'ood_core/job/adapters/slurm'

  module OodCore
    module Job
      module Adapters
        class Slurm
          class Batch

            def all_sinfo_node_fields
              {
                procs: '%c',
                procs_by_state: '%C',
                name: '%n',
                nodes_by_state: '%F',
                features: '%f',
                partition: '%R',
                partition_state: '%a',
                total_memory: '%m',
                free_memory: '%e'
              }
            end

            def nodes
              args = all_sinfo_node_fields.values.join(UNIT_SEPARATOR)
              output = call('sinfo', '-ho', "#{RECORD_SEPARATOR}#{args}")

              output.each_line(RECORD_SEPARATOR).map do |line|
                values = line.chomp(RECORD_SEPARATOR).strip.split(UNIT_SEPARATOR)

                next if values.empty?

                data = Hash[all_sinfo_node_fields.keys.zip(values)]
                data[:name] = data[:name].to_s.split(',').first
                data[:features] = data[:features].to_s.split(',')
                data[:procs_by_state] = data[:procs_by_state].to_s.split('/')
                data[:nodes_by_state] = data[:nodes_by_state].to_s.split('/')
                NodeInfo.new(**data)
              end.compact
            end
          end

          # ADDING NODE METHOD AS OODv3.1.x DOES NOT HAVE THIS METHOD
          def nodes
            @slurm.nodes
          end

        end
      end
    end
  end

  Rails.logger.info 'Executing Slurm nodes method extension completed'
end