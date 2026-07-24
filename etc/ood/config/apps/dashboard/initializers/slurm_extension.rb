# Slurm Adapter Extensions to extract metrics with sacct
Rails.application.config.after_initialize do
  Rails.logger.info 'Executing Slurm extension ...'
  require 'ood_core/job/adapters/slurm'

  module OodCore
    module Job
      module Adapters
        class Slurm
          class Batch
            def metrics_fields
              {
                # The user name of the user who ran the job.
                user: 'User',
                # The group name of the user who ran the job.
                group_name: 'Group',
                # Job Id for reference
                job_id: 'JobId',
                # The job's elapsed time.
                elapsed: 'Elapsed',
                # Minimum required memory for the job
                req_mem: 'ReqMem',
                # Count of allocated CPUs
                alloc_cpus: 'AllocCPUS',
                # Number of requested CPUs.
                req_cpus: 'ReqCPUS',
                # What the timelimit was/is for the job
                time_limit: 'Timelimit',
                # Displays the job status, or state
                state: 'State',
                # The sum of the SystemCPU and UserCPU time used by the job or job step
                total_cpu: 'TotalCPU',
                # Maximum resident set size of all tasks in job.
                max_rss: 'MaxRSS',
                # The time the job was submitted. In the same format as End.
                submit: 'Submit',
                # Initiation time of the job. In the same format as End.
                start: 'Start',
                # Termination time of the job.
                end: 'End',
                # Trackable resources. These are the minimum resource counts requested by the job/step at submission time.
                req_tres: 'ReqTRES'
              }
            end

            def call_sacct_metrics(job_ids, from, to, timeout)
              # https://slurm.schedmd.com/sacct.html
              fields = metrics_fields
              states = ['CA','CD','F','OOM','TO']
              args = ['-P'] # OUTPUT WILL BE DELIMITED
              args.concat ['--delimiter', UNIT_SEPARATOR]
              args.concat ['-n'] # NO HEADER
              args.concat ['--units', 'G'] # MEMORY UNITS IN GIGABYTES
              args.concat ['-o', fields.values.join(',')] # REQUIRED DATA
              args.concat ['--state', states.join(',')] # FILTER BY THESE STATES
              args.concat ['-j', job_ids.join(',')] unless job_ids.empty? # FILTER BY THIS JOB IDs
              args.concat ['-S', from] if from # FROM START DATE
              args.concat ['-E', to] if to # TO END DATE

              metrics = []
              # TO AVOID ADDING SLURM BIN_PATH TO timeout
              @bin_overrides['timeout'] = 'timeout'
              # NEED TO ADD THE FULL PATH FOR sacct
              cmd = OodCore::Job::Adapters::Helper.bin_path('sacct', bin, bin_overrides)
              StringIO.open(call('timeout', timeout, cmd, *args)) do |output|
                output.each_line do |line|
                  #REPLACE BLANKS WITH NIL
                  values = line.strip.split(UNIT_SEPARATOR).map{ |value| value.blank? ? nil : value }
                  metrics << Hash[fields.keys.zip(values)] unless values.empty?
                end
              end
              metrics
            end

            def call_sshare
              # https://slurm.schedmd.com/sshare.html
              fields = { user: 'User', account: 'Account', fairshare: 'Fairshare' }
              args = ['-n'] # NO HEADER
              args.concat ['--parsable2']
              args.concat ['-n'] # NO HEADER
              args.concat ['-U'] # ONLY USER INFORMATION
              args.concat ['-o', fields.values.join(',')] # REQUIRED DATA

              fairshare = []
              StringIO.open(call('sshare', *args)) do |output|
                output.each_line do |line|
                  #REPLACE BLANKS WITH NIL
                  values = line.strip.split('|').map{ |value| value.blank? ? nil : value }
                  fairshare << Hash[fields.keys.zip(values)] unless values.empty?
                end
              end
              fairshare
            end
          end

          def metrics(job_ids: [], from: nil, to: nil, timeout: '10s')
            @slurm.call_sacct_metrics(job_ids, from, to, timeout)
          end

          def fairshare
            @slurm.call_sshare
          end

        end
      end
    end
  end

  Rails.logger.info 'Executing Slurm extension completed'
end