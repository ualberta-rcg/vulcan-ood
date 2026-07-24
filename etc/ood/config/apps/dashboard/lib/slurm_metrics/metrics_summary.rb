# frozen_string_literal: true

module SlurmMetrics
  # Class that holds all the metrics data
  class MetricsSummary
    attr_accessor :from, :to
    attr_accessor :num_jobs, :num_jgpu
    attr_accessor :tot_cpu_walltime, :tot_gpu_hours, :ave_cpu_use, :ave_cpu_req, :ave_cpu_eff, :ave_gpu_req
    attr_accessor :tot_mem_use, :ave_mem_use, :ave_mem_req, :ave_mem_eff
    attr_accessor :tot_time_use, :ave_time_use, :ave_time_req, :ave_time_eff, :ave_wait_time
    attr_accessor :ntotal_cpu, :nca_cpu, :ncd_cpu, :nf_cpu, :noom_cpu, :nto_cpu, :ntotal_gpu, :nca_gpu, :ncd_gpu, :nf_gpu, :noom_gpu, :nto_gpu

    def initialize(data = {})
      @from = data.fetch(:from, nil)
      @to = data.fetch(:to, nil)
      @from = Time.at(@from) unless @from.blank?
      @to = Time.at(@to) unless @to.blank?

      @num_jobs = data.fetch(:num_jobs, 0)
      @num_jgpu = data.fetch(:num_jgpu, 0)

      @tot_cpu_walltime = data.fetch(:tot_cpu_walltime, 0.0)
      @tot_gpu_hours = data.fetch(:tot_gpu_hours, 0.0)
      @ave_cpu_use = data.fetch(:ave_cpu_use, 0.0)
      @ave_cpu_req = data.fetch(:ave_cpu_req, 0.0)
      @ave_cpu_eff = data.fetch(:ave_cpu_eff, 0.0)
      @ave_gpu_req = data.fetch(:ave_gpu_req, 0.0)

      @tot_mem_use = data.fetch(:tot_mem_use, 0.0)
      @ave_mem_use = data.fetch(:ave_mem_use, 0.0)
      @ave_mem_req = data.fetch(:ave_mem_req, 0.0)
      @ave_mem_eff = data.fetch(:ave_mem_eff, 0.0)

      @tot_time_use = data.fetch(:tot_time_use, 0.0)
      @ave_time_use = data.fetch(:ave_time_use, 0.0)
      @ave_time_req = data.fetch(:ave_time_req, 0.0)
      @ave_time_eff = data.fetch(:ave_time_eff, 0.0)
      @ave_wait_time = data.fetch(:ave_wait_time, 0.0)

      @ntotal_cpu = data.fetch(:ntotal_cpu, 0)
      @nca_cpu = data.fetch(:nca_cpu, 0)
      @ncd_cpu = data.fetch(:ncd_cpu, 0)
      @nf_cpu = data.fetch(:nf_cpu, 0)
      @noom_cpu = data.fetch(:noom_cpu, 0)
      @nto_cpu = data.fetch(:nto_cpu, 0)

      @ntotal_gpu = data.fetch(:ntotal_gpu, 0)
      @nca_gpu = data.fetch(:nca_gpu, 0)
      @ncd_gpu = data.fetch(:ncd_gpu, 0)
      @nf_gpu = data.fetch(:nf_gpu, 0)
      @noom_gpu = data.fetch(:noom_gpu, 0)
      @nto_gpu = data.fetch(:nto_gpu, 0)
    end

    def total_jobs
      ntotal_cpu + ntotal_gpu
    end

    # ALL JOBS ARE PROCESSED APART FROM CANCELLED JOBS
    # REMOVE CANCELLED JOBS FROM TOTAL
    def eligible_jobs
      total_jobs - @nca_cpu - @nca_gpu
    end

    def empty?
      total_jobs.zero?
    end

    def to_hash
      hash = {}
      instance_variables.each do |var|
        hash[var.to_s.delete('@').to_sym] = instance_variable_get(var)
      end
      hash[:from] = hash[:from].to_i
      hash[:to] = hash[:to].to_i
      hash
    end
  end
end