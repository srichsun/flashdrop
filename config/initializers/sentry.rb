Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = [ :active_support_logger ]

  # Only report from production (no DSN elsewhere, so it stays a no-op anyway)
  config.enabled_environments = %w[production]

  # Sample 10% of requests for performance tracing
  config.traces_sample_rate = 0.1

  # Don't attach user emails/IPs to events by default
  config.send_default_pii = false
end
