# frozen_string_literal: true

module SlurmMetrics
  #
  # Calculation of Slurm metrics from sacct data.
  # Based on: https://github.com/fasrc/puppet-slurm_stats
  class MetricsProcessor

    def calculate_metrics(from, to, user_metrics, ignore_cancelled: true)
      metrics_summary = SlurmMetrics::MetricsSummary.new
      metrics_summary.from = from
      metrics_summary.to = to

      user_max_rss = 0.0
      # REVERSE METRICS TO PROCESS FIRST THE JOB STEPS AND THEN THE MAIN JOB
      user_metrics.reverse_each do |metric_hash|
        user = metric_hash.fetch(:user)
        state = metric_hash.fetch(:state)
        time_limit = SlurmMetrics::SlurmDataConverter.time_to_seconds(metric_hash.fetch(:time_limit))
        elapsed = SlurmMetrics::SlurmDataConverter.time_to_seconds(metric_hash.fetch(:elapsed))
        req_mem = SlurmMetrics::SlurmDataConverter.memory_to_gigabytes(metric_hash.fetch(:req_mem))
        max_rss = SlurmMetrics::SlurmDataConverter.memory_to_gigabytes(metric_hash.fetch(:max_rss))
        req_cpus = SlurmMetrics::SlurmDataConverter.to_integer(metric_hash.fetch(:req_cpus))
        alloc_cpus = SlurmMetrics::SlurmDataConverter.to_integer(metric_hash.fetch(:alloc_cpus))
        total_cpu = SlurmMetrics::SlurmDataConverter.time_to_seconds(metric_hash.fetch(:total_cpu))
        submit = SlurmMetrics::SlurmDataConverter.parse_date(metric_hash.fetch(:submit))
        start = SlurmMetrics::SlurmDataConverter.parse_date(metric_hash.fetch(:start))
        end_ = SlurmMetrics::SlurmDataConverter.parse_date(metric_hash.fetch(:end))
        req_tres = metric_hash.fetch(:req_tres)

        # JOB STEPS => USER IS nil
        # ONLY USE JOB STEPS TO CALCULATE MAX MEMORY
        if user.blank?
          user_max_rss = [user_max_rss, max_rss].max
          next
        end

        if req_tres.include?('gres/gpu')
          update_gpu_state(metrics_summary, state)
        else
          update_cpu_state(metrics_summary, state)
        end

        # IGNORE CANCELLED JOBS
        next if state.include?('CANCELLED') && ignore_cancelled

        # If not cancelled, process resource usage
        alloc_cpus = [alloc_cpus, req_cpus].max
        cpu_eff = elapsed.zero? ? 0.0 : (total_cpu / elapsed) / alloc_cpus

        if req_tres.include?('gres/gpu')
          gpu_req = req_tres.scan(/gres\/gpu=(\d+)/).flatten.first.to_f
          metrics_summary.num_jgpu += 1
          metrics_summary.ave_gpu_req += gpu_req
          metrics_summary.tot_gpu_hours += gpu_req * elapsed
        end

        metrics_summary.num_jobs += 1
        metrics_summary.tot_cpu_walltime += alloc_cpus * elapsed
        metrics_summary.ave_cpu_use += total_cpu
        metrics_summary.ave_cpu_req += alloc_cpus
        metrics_summary.ave_cpu_eff += cpu_eff
        metrics_summary.tot_time_use += elapsed
        metrics_summary.ave_time_req += time_limit
        metrics_summary.ave_time_eff += elapsed / time_limit unless time_limit.zero?
        metrics_summary.ave_wait_time += if start.nil?
                                           # JOB CANCELLED BEFORE STARTED
                                           end_ - submit
                                         else
                                           # JOB STARTED NORMALLY
                                           start - submit
                                         end

        # STATS CALCULATED PER JOB. AFTER PROCESSING JOB STEPS
        metrics_summary.tot_mem_use += user_max_rss
        metrics_summary.ave_mem_req += req_mem
        metrics_summary.ave_mem_eff += (user_max_rss / req_mem) unless req_mem.zero?

        # RESET MAX_RSS AFTER EVERY JOB
        user_max_rss = 0.0
      end

      normalize_data(metrics_summary)
      metrics_summary
    end

    def update_gpu_state(metrics_summary, state)
      if state.include?('CANCELLED')
        metrics_summary.nca_gpu += 1
      elsif state.include?('COMPLETED')
        metrics_summary.ncd_gpu += 1
      elsif state.include?('FAILED')
        metrics_summary.nf_gpu += 1
      elsif state.include?('MEMORY')
        metrics_summary.noom_gpu += 1
      elsif state.include?('TIME')
        metrics_summary.nto_gpu += 1
      end
    end

    def update_cpu_state(metrics_summary, state)
      if state.include?('CANCELLED')
        metrics_summary.nca_cpu += 1
      elsif state.include?('COMPLETED')
        metrics_summary.ncd_cpu += 1
      elsif state.include?('FAILED')
        metrics_summary.nf_cpu += 1
      elsif state.include?('MEMORY')
        metrics_summary.noom_cpu += 1
      elsif state.include?('TIME')
        metrics_summary.nto_cpu += 1
      end
    end

    def normalize_data(metrics_summary)
      metrics_summary.num_jobs = [metrics_summary.num_jobs, 1].max
      metrics_summary.num_jgpu = [metrics_summary.num_jgpu, 1].max
      metrics_summary.ave_cpu_use /= metrics_summary.num_jobs
      metrics_summary.ave_cpu_req /= metrics_summary.num_jobs
      metrics_summary.ave_cpu_eff *= 100 / metrics_summary.num_jobs
      metrics_summary.ave_mem_use = metrics_summary.tot_mem_use / metrics_summary.num_jobs
      metrics_summary.ave_mem_req /= metrics_summary.num_jobs
      metrics_summary.ave_mem_eff *= 100 / metrics_summary.num_jobs
      metrics_summary.ave_time_use = metrics_summary.tot_time_use / metrics_summary.num_jobs
      metrics_summary.ave_time_req /= metrics_summary.num_jobs
      metrics_summary.ave_time_eff *= 100 / metrics_summary.num_jobs
      metrics_summary.ave_wait_time /= metrics_summary.num_jobs

      metrics_summary.ave_gpu_req /= metrics_summary.num_jgpu

      # NORMALIZE TIME TO HOURS
      metrics_summary.ave_cpu_use /= 3600.0
      # TIME WILL BE FORMATTED IN HH:mm and mm:ss
      #metrics_summary.ave_time_use /= 3600.0
      #metrics_summary.ave_time_req /= 3600.0
      #metrics_summary.ave_wait_time /= 3600.0
      metrics_summary.tot_cpu_walltime /= 3600.0
      metrics_summary.tot_gpu_hours /= 3600.0
      #metrics_summary.tot_time_use /= 3600.0

      # ADD TOTALS
      metrics_summary.ntotal_cpu = metrics_summary.nca_cpu + metrics_summary.ncd_cpu + metrics_summary.nf_cpu + metrics_summary.noom_cpu + metrics_summary.nto_cpu
      metrics_summary.ntotal_gpu = metrics_summary.nca_gpu + metrics_summary.ncd_gpu + metrics_summary.nf_gpu + metrics_summary.noom_gpu + metrics_summary.nto_gpu
    end
  end
end
