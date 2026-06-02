source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
# S3 client for Active Storage (Tigris object storage is S3-compatible)
gem "aws-sdk-s3", require: false

# --- Auth / authorization / multi-tenancy ---
gem "devise"          # Authentication: sign up, log in, password, session
gem "pundit"          # Authorization: owner / staff permissions
gem "acts_as_tenant"  # Row-level multi-tenancy, auto-scopes by tenant_id
gem "aasm"            # Order state machine (pending -> paid -> shipped)
gem "pg_search"       # Postgres full-text / trigram product search
gem "sidekiq"         # Background jobs (used in production)
gem "redis"           # Backing store for Sidekiq

# Observability
gem "sentry-ruby"     # Error tracking
gem "sentry-rails"    # Sentry's Rails integration
gem "lograge"         # Condense request logs into single-line JSON

group :development, :test do
  # Catch N+1 queries (logs in development, raises in test)
  gem "bullet"

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"

  # Block risky migrations that would lock a big table
  gem "strong_migrations"

  # Load local secrets from .env into ENV
  gem "dotenv-rails"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Preview outgoing emails in the browser during development
  gem "letter_opener_web"
end

group :test do
  # Test coverage report
  gem "simplecov", require: false

  # Truncate the DB for threaded specs (transactions can't be shared across connections)
  gem "database_cleaner-active_record"
end

# Pagination
gem "pagy", "~> 9.0"

# REST API auth + rate limiting
gem "jwt"
gem "rack-attack"
