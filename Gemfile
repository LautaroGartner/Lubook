source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"

# --- Phase 1 additions ---
gem "devise"
gem "omniauth-github"
gem "omniauth-rails_csrf_protection"
gem "pundit"
gem "pagy", "~> 9.3"
gem "rack-attack"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "letter_opener"
  gem "bullet"
  gem "bundler-audit", require: false
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
  gem "capybara"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
end

gem "dockerfile-rails", ">= 1.7", group: :development
