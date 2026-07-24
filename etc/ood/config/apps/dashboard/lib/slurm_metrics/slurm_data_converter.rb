# frozen_string_literal: true

module SlurmMetrics
  # Utility methods to covert string data from the Slurm response.
  class SlurmDataConverter
    UNKNOWN_DATES = %w[N/A NONE UNKNOWN].freeze

    def self.time_to_seconds(time)
      return 0.0 if time.blank?

      time = time.gsub('UNLIMITED', '365-00:00:00').gsub('Partition_Limit', '365-00:00:00')

      days = 0
      hours = 0
      if time.include?('-')
        days = time.split('-')[0].to_i * 86_400
        time = time.split('-')[1]
      end

      time_parts = time.split(':')
      hours = time_parts[0].to_i * 3_600 if time_parts.length > 2
      minutes = time_parts[-2].to_i * 60
      secs = time_parts[-1].to_f

      days + hours + minutes + secs
    end

    def self.parse_date(date_string)
      return nil if date_string.blank? || UNKNOWN_DATES.include?(date_string.to_s.upcase)

      Time.parse(date_string.to_s).to_i
    end

    def self.format_start_of_day(timestamp)
      timestamp.strftime("%Y-%m-%dT00:00:00")
    end

    def self.format_date(timestamp)
      timestamp.strftime("%Y-%m-%d")
    end

    def self.memory_to_gigabytes(memory)
      return 0.0 if memory.blank?

      memory.gsub('G', '').to_f
    end

    def self.to_integer(number)
      return 0 if number.blank?

      number.to_i
    end

    def self.to_float(number)
      return 0.0 if number.blank?

      number.to_f
    end
  end
end
