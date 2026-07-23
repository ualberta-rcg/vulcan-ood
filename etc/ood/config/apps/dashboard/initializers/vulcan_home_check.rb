# vulcan_home_check.rb — gate the dashboard landing page on account provisioning.
#
# A user can authenticate via OIDC (so the PUN starts) before their Vulcan home
# directory is fully provisioned, or before they've been granted Vulcan access.
# Instead of dropping them into a broken session, show a friendly notice.
#
# Provisioned-signal: ~/.bashrc (skel). The OOIDC email pre-hook only creates
# ~/ondemand, so an unprovisioned home lacks skel files. If the account isn't in
# passwd at all, treat it as "no access yet".
require "etc"

Rails.application.config.after_initialize do
  DashboardController.class_eval do
    before_action :vulcan_provisioning_check, only: [:index]

    private

    def vulcan_provisioning_check
      username = respond_to?(:current_user) ? current_user.username.to_s : (Etc.getlogin || "")
      return if username.empty?

      begin
        Etc.getpwnam(username)
      rescue ArgumentError
        @vulcan_reason = :no_access
        render("dashboard/vulcan_no_home", layout: "application") and return
      end

      home = File.expand_path("~#{username}")
      unless File.exist?(File.join(home, ".bashrc"))
        @vulcan_reason = :provisioning
        render("dashboard/vulcan_no_home", layout: "application") and return
      end
    rescue => e
      Rails.logger.warn("vulcan_provisioning_check: #{e.class}: #{e.message}")
      # Never block the dashboard on an internal error.
      true
    end
  end
end
