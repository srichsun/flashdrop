require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Use Tigris (S3-compatible) only when its env vars are actually set; otherwise
  # fall back to the local disk so a missing/incomplete object-store config can
  # never break the deploy. Set ACTIVE_STORAGE_SERVICE to force a service.
  config.active_storage.service =
    if ENV["ACTIVE_STORAGE_SERVICE"].present?
      ENV["ACTIVE_STORAGE_SERVICE"].to_sym
    elsif ENV["BUCKET_NAME"].present? && ENV["AWS_ACCESS_KEY_ID"].present?
      :tigris
    else
      :local
    end

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Condense each request into one JSON line (easier to read and search).
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  # Don't log the health check ping (Render hits /up constantly). Lograge
  # replaces the default logger, so silence_healthcheck_path doesn't cover it.
  config.lograge.ignore_actions = [ "Rails::HealthController#show" ]
  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:request_id],
      tenant_id: event.payload[:tenant_id],
      user_id: event.payload[:user_id]
    }
  end

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Run jobs in-process on the free tier (no Redis/worker needed).
  # Switch to :sidekiq once a Redis instance and a worker process are available.
  config.active_job.queue_adapter = :async

  # Email via SMTP. Set the SMTP_* env vars (SendGrid / Resend / Brevo ...) to
  # turn delivery on; until then deliveries are skipped (no crash).
  config.action_mailer.perform_deliveries = ENV["SMTP_ADDRESS"].present?
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "merchant-os.onrender.com"), protocol: "https"
  }
  smtp_port = ENV.fetch("SMTP_PORT", "587").to_i
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: smtp_port,
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    # Port 465 uses implicit TLS; 587 uses STARTTLS.
    tls: smtp_port == 465,
    enable_starttls_auto: smtp_port != 465
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
