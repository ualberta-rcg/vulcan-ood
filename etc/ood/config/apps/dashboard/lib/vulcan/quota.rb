# Vulcan::Quota — reads the user's disk quotas (via the Alliance diskusage_report
# tool) for /home, /scratch, /project. Rendered by the dashboard quota widget.
# Runs in the PUN as the current user; safe to call at render time.
module Vulcan
  class Quota
    UNITS = {
      "" => 1, "B" => 1,
      "K" => 1024, "M" => 1024**2, "G" => 1024**3, "T" => 1024**4, "P" => 1024**5,
      "KB" => 1000, "MB" => 10**6, "GB" => 10**9, "TB" => 10**12,
      "KiB" => 1024, "MiB" => 1024**2, "GiB" => 1024**3, "TiB" => 1024**4, "PiB" => 1024**5
    }.freeze

    class << self
      def to_bytes(s)
        m = s.to_s.strip.match(/^([\d.]+)\s*([A-Za-z]*)$/)
        return 0.0 unless m
        m[1].to_f * (UNITS[m[2]] || 1)
      end

      def human(b)
        return "0 B" if b.nil? || b <= 0
        %w[B KiB MiB GiB TiB PiB].each do |u|
          return format("%.0f %s", b, u) if b < 1024
          b /= 1024.0
        end
        format("%.0f EiB", b)
      end

      # Returns array of {path:, scope:, used:, limit:, pct:}
      def all
        out = `timeout 15 /cvmfs/soft.computecanada.ca/custom/bin/computecanada/diskusage_report 2>/dev/null`.to_s
        rows = []
        out.each_line do |line|
          next unless line =~ %r{^\s*(/(?:home|scratch|project))\s+\(([^)]+)\)\s+(.*)$}
          path  = Regexp.last_match(1)
          scope = Regexp.last_match(2)
          rest  = Regexp.last_match(3).squeeze(" ")
          parts = rest.split("/")
          next if parts.size < 2
          used  = to_bytes(parts[0])
          limit = to_bytes(parts[1].to_s.split.first.to_s)
          rows << {
            path: path, scope: scope, used: used, limit: limit,
            pct: limit.positive? ? (used / limit * 100.0) : 0.0
          }
        end
        rows
      rescue StandardError
        []
      end
    end
  end
end
