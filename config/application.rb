require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lubook
  class Application < Rails::Application
    mailer_address = ENV.fetch("MAILER_FROM", "contact@paideiastudios.com")
    branded_mailer_address = mailer_address.include?("<") ? mailer_address : "Lubook <#{mailer_address}>"
    config.action_mailer.default_options = { from: branded_mailer_address }
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1
    config.middleware.use Rack::Attack

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
